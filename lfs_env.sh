#!/bin/bash

echo switching to lfs user
if [ "${USER:-$(whoami)}" != 'lfs' ]; then
  echo 'must source this script as the lfs user'
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

echo set LFS_TGT
export LFS_TGT=$(uname -m)-lfs-linux-gnueabihf

echo set LFS, assuming the destination disk, /dev/sdc, has raspbian lite preinstalled
export LFS=/mnt/lfsdisk

echo if not mounted, mount the disk and clear it
if ! mount | grep -F "$device on $LFS type ext4" >/dev/null; then
  if ! sudo mkdir -p "$LFS" ||
    ! sudo chown lfs:lfs "$LFS" ||
    ! sudo mount "$device" "$LFS" ||
    ! sudo rm -rf "$LFS"/*
  then
    echo "failed to setup the disk at $LFS"
    return 1
  fi
fi

echo create sources dir
cd "$LFS"
if ! mkdir -p sources ||
  ! chmod -v a+wt sources
then
  echo 'failed to setup pilfs sources dir'
  return 1
fi
cd sources

echo if not already present, download packages
if ! [ -e wget-list ]; then
  if ! wget https://intestinate.com/pilfs/scripts/wget-list; then
    echo 'failed to download wget-list'
    return 1
  fi
  if ! wget --input-file=wget-list --continue --directory-prefix="$LFS"/sources
  then
    echo 'failed to download pilfs sources'
    return 1
  fi
fi

echo creating system dir tree
if ! sudo mkdir -pv "$LFS"/{bin,etc,lib,sbin,usr,var,tools} ||
  ! sudo chown lfs "$LFS"/{bin,etc,lib,sbin,usr,var,tools}
then
  echo failed to create system dir tree
fi

echo create isolated bash_profile
if ! grep -F 'exec env -i HOME="$HOME"' ~/.bash_profile > /dev/null; then
  cat > ~/.bash_profile << EOF
exec env -i HOME="\$HOME" TERM="\$TERM" PS1="\$PS1" /bin/bash
EOF
fi

echo modifying bashrc
if ! grep -F 'LFS=' ~lfs/.bashrc >/dev/null; then
  sed -i '' \
    -e 's/#\(alias l.*ls \)/\1/' \
    -e 's/#\(export GCC_COLORS=\)/\1/' \
    ~lfs/.bashrc

  cat >> ~lfs/.bashrc << EOF

alias ..='cd ..'

set +h
umask 022
LFS=$LFS
LC_ALL=POSIX
LFS_TGT=$LFS_TGT
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF
fi

echo ensure system bashrc does not interfere with environment
if [ -e /etc/bash.bashrc ]; then
  sudo mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE
fi

echo sourcing bash_profile
source ~/.bash_profile
