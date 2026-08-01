#!/bin/sh
# EmuELEC -> boot back into Armbian on eMMC.
#
# All this does is remove /boot/emuelec/TRIGGER from the eMMC boot partition.
# Without that file the u-boot script skips the chainload block and Armbian
# boots as usual.
#
# Why it has to run from Linux: u-boot can test for the file but cannot delete
# it (no ext4 write support in this build). EmuELEC, being a full Linux, has
# no such problem.
#
# IMPORTANT: EmuELEC's /usr is a read-only squashfs. Save this script to
# /storage (writable and persistent) before running it.
set -e

EMMC_BOOT_DEV="${EMMC_BOOT_DEV:-/dev/mmcblk0p1}"
M=/tmp/emmcboot

mkdir -p "$M"
if ! mountpoint -q "$M"; then
  mount "${EMMC_BOOT_DEV}" "$M"
fi

if [ -e "$M/emuelec/TRIGGER" ]; then
  rm -f "$M/emuelec/TRIGGER"
  echo "TRIGGER removed. Next boot goes to Armbian (eMMC)."
else
  echo "TRIGGER was not present. Next boot goes to Armbian (eMMC)."
fi

sync
umount "$M"
echo "Rebooting in 3 seconds..."
sleep 3
reboot
