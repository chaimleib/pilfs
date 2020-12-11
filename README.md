# pilfs

Automatically build a Linux From Scratch system for a Raspberry Pi. I know that
there is [an official
script](https://gitlab.com/gusco/pilfs-scripts/tree/aarch64), but I want to
learn for myself. Also, those scripts are missing some initial setup important
to Americans like me.

Based on:

* https://intestinate.com/pilfs/guide.html
* http://www.linuxfromscratch.org/lfs/view/development/index.html

## Prerequisites

* Raspberry Pi
* 2x SD cards >=4GB, Class 10 and/or U-rated
* Means to connect Pi to internet
* US keyboard
* Monitor

## Instructions

1. Create a Raspbian Lite boot disk on an SD card. https://www.raspberrypi.org/software/

2. Boot your pi from it. Default login is `pi` and password is `raspberry`.

3. While the pi is rebooting, go ahead and install Raspbian again on another SD card.

4. Change the default password with `passwd`.

5. `sudo raspi-config` and configure your internet connection. Other options, like locale, keyboard and timezone will be set by the install script.

6. Finish the `raspi-config`. Reboot as prompted.


7. `sudo apt update && sudo apt install -y git && git clone https://github.com/chaimleib/pilfs`

8. `TZ=<your_timezone_name> source pilfs/install.sh` and follow the prompts

9. As the lfs user, run `source pilfs/lfs_env.sh`
