#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
#
# installtoemmc.sh --- unified eMMC dual-boot installer for adapted Amlogic
# TV boxes running EmuELEC.
#
# ONE program, ONE embedded board table. To support a new box, add a case
# entry in board_config() below -- do NOT create another per-model script.
#
# METHOD (for locked / proprietary Amlogic partition-table boxes such as the
# X98mini): the stock Android u-boot cannot repartition the eMMC and does not
# read an MBR, but its autoscript carries a "cfgloademmc" fallback that scans
# eMMC partitions 1..0x1F for a FAT partition holding a "cfgload" file; if it
# finds one it sets ce_on_emmc=yes and boots from LABEL=CE_FLASH /
# LABEL=CE_STORAGE instead of the SD/USB. So no bootloader replacement is
# needed. Rather than repartition (which the stock u-boot would ignore) we
# REUSE two existing factory Android named partitions:
#   - a mid-sized one  -> reformatted FAT32, label CE_FLASH   (boot files)
#   - the largest one  -> reformatted ext4,  label CE_STORAGE (persistent /storage)
#
# Bootloader / env / tee and every other partition are left untouched, so the
# SD/USB installation remains a working fallback. Android itself will no longer
# boot afterwards (its partitions are repurposed), which is expected on these
# boxes since they are not used as Android devices.
#
# The official CoreELEC "ceemmc" tool mis-handles these boards' Android
# partition layouts (segfaults), so this does the equivalent steps by hand.
#
# Usage:
#   installtoemmc.sh <board>      e.g.  installtoemmc.sh x98mini
#   installtoemmc.sh -<board>     e.g.  installtoemmc.sh -x98mini   (same thing)
#   installtoemmc.sh auto         auto-detect the board from the eMMC layout
#   installtoemmc.sh list         list supported boards

set -e

CE_FLASH_LABEL="CE_FLASH"
CE_STORAGE_LABEL="CE_STORAGE"
MNT_FLASH="/tmp/emmc_flash"
MNT_STORAGE="/tmp/emmc_storage"

die() { echo "ERROR: $*" >&2; exit 1; }

# Size of a block device in MiB, read from sysfs (EmuELEC's busybox has no
# blockdev/lsblk). /sys/class/block/<name>/size is in 512-byte sectors.
dev_size_mb() {
    local sect
    sect=$(cat "/sys/class/block/${1##*/}/size" 2>/dev/null)
    [ -n "$sect" ] || return 1
    echo $(( sect / 2048 ))
}

# Some boxes reuse the Android "super" dynamic-partition container as CE_FLASH.
# On those, CoreELEC's opentee_linuxdriver.service (tee-loader/dovi-loader)
# assembles the super partition via device-mapper (dynpart-*) and mounts
# /android/{system,vendor,odm,oem} to run the TEE supplicant + Dolby Vision.
# Those pin the target device busy. Tear the whole stack down before formatting.
# TEE / Dolby Vision are not used for retro gaming, so losing them is fine.
teardown_android_super() {
    echo ">>> Tearing down Android TEE / Dolby-Vision stack (frees ${FLASH_DEV})..."
    systemctl stop opentee_linuxdriver 2>/dev/null || true
    # kill processes still executing out of /android (e.g. tee-supplicant)
    local p pid
    for p in /proc/[0-9]*; do
        pid=${p#/proc/}
        if grep -qs '/android/' "$p/maps" 2>/dev/null \
           || readlink "$p/cwd" 2>/dev/null | grep -qs '/android/'; then
            kill "$pid" 2>/dev/null || true
        fi
    done
    sleep 1
    # unmount the android mounts (lazy if still busy)
    local m
    for m in /android/system /android/vendor /android/odm /android/oem /android/product; do
        if mountpoint -q "$m" 2>/dev/null; then
            umount "$m" 2>/dev/null || umount -l "$m" 2>/dev/null || true
        fi
    done
    # remove the device-mapper dynamic partitions that pin FLASH_DEV
    local d
    for d in $(dmsetup ls 2>/dev/null | awk 'NF && $1!="No"{print $1}'); do
        dmsetup remove "$d" 2>/dev/null || dmsetup remove -f "$d" 2>/dev/null || true
    done
}

# ---------------------------------------------------------------------------
# Board table. board_config <board> sets, for the selected board:
#   FLASH_DEV      factory partition to reuse for boot files (-> CE_FLASH, FAT32)
#   STORAGE_DEV    factory partition to reuse for /storage    (-> CE_STORAGE, ext4)
#   FLASH_MIN_MB / FLASH_MAX_MB   sanity range for FLASH_DEV   (anti-brick guard)
#   STORAGE_MIN_MB                minimum size for STORAGE_DEV
#   DESC           human description
#
# To add a new box: add a case entry here and append its name to BOARDS.
# ---------------------------------------------------------------------------
BOARDS="x98mini e900v22c"

board_config() {
    SUPER_TEARDOWN=""   # default: boards that don't reuse Android 'super'
    case "$1" in
    x98mini)
        # Reuse Android 'super' (eMMC part 28/0x1C, ~2.25GB) and 'userdata'
        # (part 29/0x1D, ~26GB). Both are surfaced by the Amlogic MMC driver
        # as named nodes /dev/super and /dev/userdata.
        FLASH_DEV="/dev/super"
        STORAGE_DEV="/dev/userdata"
        FLASH_MIN_MB=1500;  FLASH_MAX_MB=4000
        STORAGE_MIN_MB=10000
        SUPER_TEARDOWN="yes"   # FLASH_DEV is the Android 'super' dm container
        DESC="X98mini (Amlogic S905W2/S4, 32GB eMMC)"
        ;;
    e900v22c)
        # Unlike the X98mini, this 8GB eMMC has only ONE factory partition big
        # enough to be useful (data, 5.5GB). So boot and storage can't both use
        # a large partition: system (1GB FAT) -> CE_FLASH holds SYSTEM+kernel;
        # data (5.5GB ext4) -> CE_STORAGE is the large ROM partition (users want
        # room for ROMs).
        # SYSTEM must fit in the 1GB system partition. The size check below
        # refuses to install and explains why if it won't fit.
        # No Android 'super' dynamic partition on this board, so no teardown needed.
        FLASH_DEV="/dev/system"
        STORAGE_DEV="/dev/data"
        FLASH_MIN_MB=900;   FLASH_MAX_MB=1100
        STORAGE_MIN_MB=4000
        SUPER_TEARDOWN=""
        DESC="E900V22C (Amlogic S905L3A/G12A, 8GB eMMC)"
        ;;
    *)
        return 1
        ;;
    esac
    return 0
}

list_boards() {
    echo "Supported boards:"
    for b in $BOARDS; do
        board_config "$b" && printf "  %-12s %s\n" "$b" "$DESC"
    done
}

auto_detect() {
    local b f s
    for b in $BOARDS; do
        board_config "$b" || continue
        [ -b "$FLASH_DEV" ] && [ -b "$STORAGE_DEV" ] || continue
        f=$(dev_size_mb "$FLASH_DEV") || continue
        s=$(dev_size_mb "$STORAGE_DEV") || continue
        if [ "$f" -ge "$FLASH_MIN_MB" ] && [ "$f" -le "$FLASH_MAX_MB" ] \
           && [ "$s" -ge "$STORAGE_MIN_MB" ]; then
            echo "$b"; return 0
        fi
    done
    return 1
}

# ---- argument handling ----
ARG="${1:-}"
case "$ARG" in
    ""|-h|--help|help)
        echo "Usage: $(basename "$0") <board>|auto|list"
        list_boards
        exit 0 ;;
    list|--list)
        list_boards; exit 0 ;;
    auto|--auto)
        BOARD=$(auto_detect) || die "Could not auto-detect a supported board from the eMMC layout."
        echo ">>> Auto-detected board: ${BOARD}" ;;
    -*)
        BOARD="${ARG#-}" ;;   # allow -x98mini
    *)
        BOARD="$ARG" ;;
esac

board_config "$BOARD" || { echo "Unknown board: ${BOARD}" >&2; echo; list_boards; exit 1; }

# ---- safety checks ----
[ "$(id -u)" = "0" ] || die "Must run as root."
[ -b "$FLASH_DEV" ]   || die "${FLASH_DEV} not found - board '${BOARD}' expects this factory partition. Wrong board/device?"
[ -b "$STORAGE_DEV" ] || die "${STORAGE_DEV} not found - wrong board/device?"

# Refuse if we are already booted from eMMC (/flash would be the target itself).
FLASH_SRC=$(awk '$2=="/flash"{print $1}' /proc/mounts)
case "$FLASH_SRC" in
    "$FLASH_DEV"|"$STORAGE_DEV") die "Already running from eMMC - nothing to do." ;;
esac

FLASH_SIZE_MB=$(dev_size_mb "$FLASH_DEV")   || die "Cannot read size of ${FLASH_DEV}."
STORAGE_SIZE_MB=$(dev_size_mb "$STORAGE_DEV") || die "Cannot read size of ${STORAGE_DEV}."

# Anti-brick sanity: refuse if the partition sizes are wildly off what this
# board expects - could mean it is not really this board or the layout changed.
if [ "$FLASH_SIZE_MB" -lt "$FLASH_MIN_MB" ] || [ "$FLASH_SIZE_MB" -gt "$FLASH_MAX_MB" ]; then
    die "Unexpected size for ${FLASH_DEV}: ${FLASH_SIZE_MB}MB (expected ${FLASH_MIN_MB}-${FLASH_MAX_MB}MB). Refusing - wrong device?"
fi
if [ "$STORAGE_SIZE_MB" -lt "$STORAGE_MIN_MB" ]; then
    die "Unexpected size for ${STORAGE_DEV}: ${STORAGE_SIZE_MB}MB (expected >=${STORAGE_MIN_MB}MB). Refusing - wrong device?"
fi

# The contents of /flash (SYSTEM squashfs + kernel.img) must fit on FLASH_DEV.
# This matters most for boards like the E900V22C with a small boot partition
# (system, 1GB). Check this up front so we refuse before touching any
# partition, instead of failing with no-space-left mid-copy after Android has
# already been erased.
FLASH_NEED_MB=$(du -sm /flash 2>/dev/null | cut -f1)
FLASH_AVAIL_MB=$(( FLASH_SIZE_MB - 16 ))   # reserve for the FAT32 table/overhead
if [ -n "$FLASH_NEED_MB" ] && [ "$FLASH_NEED_MB" -gt "$FLASH_AVAIL_MB" ]; then
    die "/flash needs ${FLASH_NEED_MB}MB, but ${FLASH_DEV} only has about ${FLASH_AVAIL_MB}MB available.
Refusing to install (no partition has been touched).

The firmware currently running is too large to fit on this board's boot
partition. Re-flash your SD/USB with a current build and try again."
fi

cat <<EOF
================================================================
 EmuELEC eMMC dual-boot installer   --   board: ${BOARD}
 ${DESC}
================================================================
 This will ERASE and reformat two eMMC partitions:

   ${FLASH_DEV}    (${FLASH_SIZE_MB}MB)  -> FAT32, label ${CE_FLASH_LABEL}
   ${STORAGE_DEV}  (${STORAGE_SIZE_MB}MB)  -> ext4,  label ${CE_STORAGE_LABEL}

 These are factory Android partitions. Android will no longer boot
 after this. Bootloader / env / tee and every other partition are
 left untouched. The current SD/USB EmuELEC system + storage will be
 copied to eMMC; remove the SD/USB and reboot to boot from eMMC.

 IRREVERSIBLE without re-flashing Android separately.
================================================================
EOF

read -r -p "Type YES to continue: " CONFIRM
[ "$CONFIRM" = "YES" ] || { echo "Aborted."; exit 1; }

[ "${SUPER_TEARDOWN}" = "yes" ] && teardown_android_super

echo ">>> Formatting ${FLASH_DEV} as FAT32 (${CE_FLASH_LABEL})..."
umount "$FLASH_DEV" 2>/dev/null || true
mkfs.vfat -F 32 -n "$CE_FLASH_LABEL" "$FLASH_DEV"

echo ">>> Formatting ${STORAGE_DEV} as ext4 (${CE_STORAGE_LABEL})..."
umount "$STORAGE_DEV" 2>/dev/null || true
mkfs.ext4 -F -L "$CE_STORAGE_LABEL" "$STORAGE_DEV"

mkdir -p "$MNT_FLASH" "$MNT_STORAGE"
mount "$FLASH_DEV" "$MNT_FLASH"
mount "$STORAGE_DEV" "$MNT_STORAGE"

echo ">>> Copying boot files from /flash to ${CE_FLASH_LABEL}..."
cp -a /flash/. "$MNT_FLASH/"

echo ">>> Copying current /storage to ${CE_STORAGE_LABEL} (this can take a while)..."
cp -a /storage/. "$MNT_STORAGE/"

sync
umount "$MNT_FLASH"
umount "$MNT_STORAGE"

cat <<EOF

================================================================
 Done. Remove the SD/USB and power-cycle the device.
 The stock Android u-boot's cfgloademmc fallback will detect
 ${CE_FLASH_LABEL} / ${CE_STORAGE_LABEL} on eMMC and boot EmuELEC from there.

 IMPORTANT: this bootloader always tries SD, then USB, before eMMC -
 on EVERY power-on, not just this first one. As long as a bootable
 SD/USB is plugged in, it will ALWAYS boot from there instead of
 eMMC. A software reboot (from the EmulationStation menu or the
 "reboot" command) does not eject it for you - you must physically
 remove the SD/USB each time you want to boot from eMMC.

 If it does not boot, re-insert the SD/USB (untouched by this
 script) to fall back to the SD/USB installation and report it.
================================================================
EOF
