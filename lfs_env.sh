#!/bin/bash

echo switching to lfs user
if [ "$USER" != 'lfs' ]; then
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

echo mount the disk and clear it
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

echo creating system dir tree
if ! sudo mkdir -pv "$LFS"/{bin,etc,lib,sbin,usr,var,tools} ||
  ! sudo chown lfs "$LFS"/{bin,etc,lib,sbin,usr,var,tools}
then
  echo failed to create system dir tree
fi
