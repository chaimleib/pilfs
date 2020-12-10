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
echo gpu_mem=16 | sudo tee -a /boot/config.txt >/dev/null

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
if ! sudo adduser lfs; then
  echo 'failed to create user lfs'
  return 1
fi
if ! sudo adduser lfs sudo; then
  echo 'failed to add lfs user to sudo group'
  return 1
fi
sudo adduser lfs video
echo 'lfs ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/010_lfs-nopasswd

echo switching to lfs user
if ! sudo su lfs; then
  echo 'failed to switch to lfs user'
  return 1
fi

echo get first ext4 disk besides the boot disk
device=$(sudo blkid |
  grep -v '^/dev/mmcblk' |
  grep -F ext4 |
  cut -d: -f1 |
  head -n1)
if [ -z "$device" ]; then
  echo "error: Could not find external disk"
  return 1
fi

echo assuming the destination disk, /dev/sdc, has raspbian lite preinstalled
export LFS=/mnt/lfsdisk

echo mount the disk and clear it
if ! sudo mkdir -p "$LFS" ||
  ! sudo chown lfs:lfs "$LFS" ||
  ! sudo mount "$device" "$LFS" ||
  ! sudo rm -rf "$LFS"/*
then
  echo "failed to setup the disk at $LFS"
  return 1
fi

echo download pilfs packages
cd "$LFS"
if ! mkdir -p sources ||
  ! chmod -v a+wt sources
then
  echo 'failed to setup pilfs sources dir'
  return 1
fi
cd sources

if ! wget https://intestinate.com/pilfs/scripts/wget-list ||
  ! wget --input-file=wget-list --continue --directory-prefix="$LFS"/sources
then
  echo 'failed to download pilfs sources'
  return 1
fi
