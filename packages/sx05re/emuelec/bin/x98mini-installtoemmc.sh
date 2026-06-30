#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
#
# X98mini (S905W2/S4) eMMC dual-boot installer.
#
# Background: X98mini boots EmuELEC from the SD card by borrowing the stock
# Android u-boot's autoscript mechanism (aml_autoscript on the SD card's
# boot partition). That same autoscript already contains a "cfgloademmc"
# fallback that scans eMMC partitions 1-0x1F for a FAT partition holding a
# "cfgload" file; if found it sets ce_on_emmc=yes and boots from
# LABEL=CE_FLASH / LABEL=CE_STORAGE instead of the SD card's
# LABEL=EMUELEC / LABEL=STORAGE. So no bootloader replacement is needed.
#
# The official CoreELEC "ceemmc" tool does not handle this board's Android
# partition layout correctly, so this script does the equivalent steps
# manually, reusing two existing Android partitions that are safe to
# repurpose because Android itself is never booted on this device:
#   - /dev/super     (eMMC partition 28 / 0x1C, ~2.25GB) -> reformatted FAT,
#                      becomes CE_FLASH (boot files)
#   - /dev/userdata  (eMMC partition 29 / 0x1D, ~26GB)   -> reformatted ext4,
#                      becomes CE_STORAGE (persistent /storage data)
#
# This does NOT touch bootloader, env, tee, or any other Android partition.
# Android itself will no longer boot afterwards (its /super and /userdata
# are gone), but this device is not used as an Android box, so that is
# expected and accepted.

set -e

CE_FLASH_DEV="/dev/super"
CE_STORAGE_DEV="/dev/userdata"
CE_FLASH_LABEL="CE_FLASH"
CE_STORAGE_LABEL="CE_STORAGE"
MNT_FLASH="/tmp/emmc_flash"
MNT_STORAGE="/tmp/emmc_storage"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

[ "$(id -u)" = "0" ] || die "Must run as root."

[ -b "${CE_FLASH_DEV}" ] || die "${CE_FLASH_DEV} not found - this script is only for X98mini's known eMMC layout (partition 28/29). Do not run on other devices."
[ -b "${CE_STORAGE_DEV}" ] || die "${CE_STORAGE_DEV} not found."

FLASH_SIZE_MB=$(( $(blockdev --getsize64 "${CE_FLASH_DEV}") / 1024 / 1024 ))
STORAGE_SIZE_MB=$(( $(blockdev --getsize64 "${CE_STORAGE_DEV}") / 1024 / 1024 ))

# Sanity check the partition sizes match what we expect for X98mini
# (super ~2.25GB, userdata ~26GB). Refuse to run if wildly different -
# could mean this isn't actually an X98mini or the eMMC layout changed.
if [ "${FLASH_SIZE_MB}" -lt 1500 ] || [ "${FLASH_SIZE_MB}" -gt 4000 ]; then
    die "Unexpected size for ${CE_FLASH_DEV}: ${FLASH_SIZE_MB}MB (expected ~2.25GB). Refusing to continue - wrong device?"
fi
if [ "${STORAGE_SIZE_MB}" -lt 10000 ]; then
    die "Unexpected size for ${CE_STORAGE_DEV}: ${STORAGE_SIZE_MB}MB (expected >=10GB). Refusing to continue - wrong device?"
fi

cat <<EOF
================================================================
 X98mini eMMC dual-boot installer
================================================================
 This will ERASE and reformat two eMMC partitions:

   ${CE_FLASH_DEV}    (${FLASH_SIZE_MB}MB)  -> FAT32, label ${CE_FLASH_LABEL}
   ${CE_STORAGE_DEV} (${STORAGE_SIZE_MB}MB)  -> ext4,  label ${CE_STORAGE_LABEL}

 These are Android's "super" and "userdata" partitions. Android
 will no longer boot after this. All other Android/bootloader
 partitions are left untouched.

 Current SD card's EmuELEC system + storage will be copied to
 eMMC. After this completes, remove the SD card and reboot to
 boot EmuELEC from eMMC.

 This is IRREVERSIBLE without re-flashing Android separately.
================================================================
EOF

read -r -p "Type YES to continue: " CONFIRM
[ "${CONFIRM}" = "YES" ] || { echo "Aborted."; exit 1; }

echo ">>> Formatting ${CE_FLASH_DEV} as FAT32 (${CE_FLASH_LABEL})..."
mkfs.vfat -F 32 -n "${CE_FLASH_LABEL}" "${CE_FLASH_DEV}"

echo ">>> Formatting ${CE_STORAGE_DEV} as ext4 (${CE_STORAGE_LABEL})..."
mkfs.ext4 -F -L "${CE_STORAGE_LABEL}" "${CE_STORAGE_DEV}"

mkdir -p "${MNT_FLASH}" "${MNT_STORAGE}"
mount "${CE_FLASH_DEV}" "${MNT_FLASH}"
mount "${CE_STORAGE_DEV}" "${MNT_STORAGE}"

echo ">>> Copying boot files from /flash to CE_FLASH..."
cp -a /flash/. "${MNT_FLASH}/"

echo ">>> Copying current /storage to CE_STORAGE (this can take a while)..."
cp -a /storage/. "${MNT_STORAGE}/"

sync
umount "${MNT_FLASH}"
umount "${MNT_STORAGE}"

cat <<EOF

================================================================
 Done. Remove the SD card and power-cycle the device.
 The stock Android bootloader's cfgloademmc fallback should
 detect CE_FLASH/CE_STORAGE on eMMC and boot EmuELEC from there.

 If it does not boot, re-insert the SD card to fall back to
 the SD card installation (untouched by this script) and report
 the issue.
================================================================
EOF
