#!/bin/bash

echo ensure US keyboard layout, important to ensure passwords are entered correctly
if [ -f /etc/default/keyboard ] &&
  ! grep -R 'XKBLAYOUT="us"' /etc/default/keyboard >/dev/null
then
  cat << EOF | sudo tee /etc/default/keyboard > /dev/null
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc104"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS="ctrl:nocaps"

BACKSPACE="guess"
EOF

  sudo dpkg-reconfigure -phigh console-setup
fi

echo ensure en_US.UTF-8 locale
if [ -f /etc/locale.gen ] &&
  ! grep '^en_US\.UTF-8 UTF-8' /etc/locale.gen
then
  # comment out all lines except en_US.UTF-8 UTF-8
  sudo sed -i'' \
    -e 's/^\([^#]\)/# \1/' \
    -e 's/# \(en_US\.UTF-8 UTF-8\)/\1/' \
    /etc/locale.gen
  sudo locale-gen
  sudo update-locale LANG=en_US.UTF-8
fi

echo set my timezone so that logs and file modification dates are correct
TZ=${TZ:-US/Arizona}
if ! sudo timedatectl set-timezone "$TZ"; then
  echo "failed to set timezone to $TZ"
  return 1
fi

echo maximize RAM available for compile
if ! grep '^gpu_mem=16' /boot/config.txt; then
  echo gpu_mem=16 | sudo tee -a /boot/config.txt >/dev/null
fi

echo sometimes the proxy gets set. Can\'t figure out why yet.
http_proxy= ftp_proxy=

echo install apt packages
if ! sudo apt update || ! sudo apt install -y \
  vim w3m tree \
  bison gawk m4 texinfo
then
  echo 'failed to install apt packages'
  return 1
fi

echo set root user password
sudo passwd root || return 1

echo set up lfs user
if ! grep '^lfs:' /etc/passwd; then
  if ! sudo adduser lfs; then
    echo 'failed to create user lfs'
    return 1
  fi
else
  echo lfs user already exists
fi
if ! sudo adduser lfs sudo; then
  echo 'failed to add lfs user to sudo group'
  return 1
fi
sudo adduser lfs video
if ! [ -f /etc/sudoers.d/010_lfs-nopasswd ]; then
  echo 'lfs ALL=(ALL) NOPASSWD:ALL' |
    sudo tee /etc/sudoers.d/010_lfs-nopasswd > /dev/null
fi
