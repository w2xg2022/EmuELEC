#!/bin/sh
# Sync the EmuELEC chainload payload from the USB stick to eMMC.
#
# Board-agnostic: nothing here is tied to a particular RK model. The dtb is
# stored on eMMC under the fixed name "dtb" precisely so that the u-boot block
# never has to know the board's dtb filename.
#
# WHY THIS EXISTS
#   On these boards EmuELEC boots by chainloading: the stock u-boot on eMMC
#   cannot see USB devices, so the kernel and the dtb must live on eMMC while
#   the rootfs (SYSTEM) stays on the USB stick. Writing a new EmuELEC image to
#   the stick therefore only replaces the userland -- nothing updates the copy
#   on eMMC. The machine then reports the new version in /etc/os-release while
#   still running the OLD kernel, and because the initramfs is baked into
#   KERNEL, every kernel-level and initramfs-level change silently does nothing.
#
# THE PAYLOAD IS EXACTLY TWO FILES
#   <emmc-boot>/emuelec/KERNEL   the kernel image, initramfs included
#   <emmc-boot>/emuelec/dtb      the device tree, stored under this fixed name
#   Nothing else is needed: SYSTEM, oemsplash-*.png, extlinux/ and the *.md5
#   files are all read from /flash (the USB partition) by the initramfs, which
#   only runs once the kernel is already up. u-boot reads only the two above,
#   and u-boot can only read eMMC.
#
# MD5, NOT TIMESTAMPS
#   Timestamps are unreliable here: the source is on a FAT partition and gets
#   skewed by timezone handling and by however the image was written.
#
# NOTE: a sync only takes effect on the NEXT boot -- u-boot loaded the old
# kernel long before this ran. After flashing a new image, reboot twice.
#
# Tunables (environment):
#   EMMC_BOOT_DEV    eMMC boot partition            (default /dev/mmcblk0p1)
#   DTB_NAME         source dtb filename on the USB stick; only needed when the
#                    image ships more than one and the choice is ambiguous
#   USB_WAIT_TRIES   retries while waiting for USB enumeration (default 1)
#
# Exit codes: 0 = payload is current (or was just updated)
#             1 = could not produce a usable payload

set -e

EMMC_BOOT_DEV="${EMMC_BOOT_DEV:-/dev/mmcblk0p1}"
DEST_DTB="dtb"
MNT_EMMC=""
MNT_USB=""

log() { echo "emuelec-chainload-sync: $*"; }

cleanup() {
  [ -n "${MNT_USB}" ]  && { umount "${MNT_USB}"  2>/dev/null || true; rmdir "${MNT_USB}"  2>/dev/null || true; }
  [ -n "${MNT_EMMC}" ] && { umount "${MNT_EMMC}" 2>/dev/null || true; rmdir "${MNT_EMMC}" 2>/dev/null || true; }
}
trap cleanup EXIT

[ "$(id -u)" = "0" ] || { log "must run as root"; exit 1; }

# ---------------------------------------------------------------------------
# Locate the USB EmuELEC boot partition.
#
# Prefer the label (EmuELEC sets DISTRO_BOOTLABEL="EMUELEC"), then fall back to
# scanning for a partition that actually carries a KERNEL file -- the label may
# have been changed, and more than one removable disk may be attached.
#
# When run from systemd at boot the USB stack may not have enumerated yet, so
# retry instead of failing on the first attempt.
# ---------------------------------------------------------------------------
find_usb() {
  _tries="${1:-1}"
  while [ "${_tries}" -gt 0 ]; do
    _p="$(blkid -L EMUELEC 2>/dev/null || true)"
    if [ -n "${_p}" ]; then
      _m="$(mktemp -d)"
      if mount -o ro "${_p}" "${_m}" 2>/dev/null && [ -f "${_m}/KERNEL" ]; then
        MNT_USB="${_m}"; USB_DEV="${_p}"; return 0
      fi
      umount "${_m}" 2>/dev/null || true; rmdir "${_m}" 2>/dev/null || true
    fi

    for _p in $(ls /dev/sd?1 2>/dev/null); do
      _m="$(mktemp -d)"
      if mount -o ro "${_p}" "${_m}" 2>/dev/null && [ -f "${_m}/KERNEL" ]; then
        MNT_USB="${_m}"; USB_DEV="${_p}"; return 0
      fi
      umount "${_m}" 2>/dev/null || true; rmdir "${_m}" 2>/dev/null || true
    done

    _tries=$((_tries - 1))
    [ "${_tries}" -gt 0 ] && sleep 2
  done
  return 1
}

MNT_EMMC="$(mktemp -d)"
if ! mount "${EMMC_BOOT_DEV}" "${MNT_EMMC}" 2>/dev/null; then
  log "ERROR cannot mount ${EMMC_BOOT_DEV}"
  exit 1
fi
DEST="${MNT_EMMC}/emuelec"

if ! find_usb "${USB_WAIT_TRIES:-1}"; then
  # No stick attached. If a payload is already installed this is not fatal --
  # the board can still chainload, it will just run whatever is already there.
  if [ -f "${DEST}/KERNEL" ] && [ -f "${DEST}/${DEST_DTB}" ]; then
    log "no USB EmuELEC partition found; keeping the existing payload on eMMC"
    log "if you just flashed a new image, plug the stick back in and run this again"
    exit 0
  fi
  log "ERROR no USB EmuELEC partition with a KERNEL file, and no payload on eMMC"
  exit 1
fi
log "USB EmuELEC partition = ${USB_DEV}"

# ---------------------------------------------------------------------------
# Pick the source dtb.
#
# It sits in the ROOT of the boot partition, because EmuELEC's
# bootloader/mkimage does `mcopy -o "$dtb" ::`. (ROCKNIX keeps dtbs in a
# device_trees/ subdirectory -- do not carry that assumption over.)
#
# One dtb is the normal case and is taken automatically. Several means the
# image ships more than one board, and guessing would be exactly the kind of
# silent wrong choice that produces an unbootable machine -- so ask instead.
# ---------------------------------------------------------------------------
if [ -n "${DTB_NAME}" ]; then
  SRC_DTB="${MNT_USB}/${DTB_NAME}"
  [ -f "${SRC_DTB}" ] || { log "ERROR DTB_NAME=${DTB_NAME} not found on the USB partition"; exit 1; }
else
  _count="$(ls "${MNT_USB}"/*.dtb 2>/dev/null | wc -l)"
  if [ "${_count}" -eq 0 ]; then
    log "ERROR no *.dtb on the USB partition"
    exit 1
  elif [ "${_count}" -eq 1 ]; then
    SRC_DTB="$(ls "${MNT_USB}"/*.dtb)"
  else
    log "ERROR the image ships ${_count} dtb files; set DTB_NAME to choose one:"
    for _d in "${MNT_USB}"/*.dtb; do log "  $(basename "${_d}")"; done
    exit 1
  fi
fi
log "source dtb = $(basename "${SRC_DTB}")"

mkdir -p "${DEST}"
changed=0

copy_if_different() {
  _src="$1"; _dst="$2"
  if [ ! -f "${_dst}" ] || \
     [ "$(md5sum < "${_src}" | cut -d' ' -f1)" != "$(md5sum < "${_dst}" | cut -d' ' -f1)" ]; then
    cp -f "${_src}" "${_dst}"
    log "updated $(basename "${_dst}")"
    changed=1
  fi
}

copy_if_different "${MNT_USB}/KERNEL" "${DEST}/KERNEL"
copy_if_different "${SRC_DTB}" "${DEST}/${DEST_DTB}"

sync
if [ "${changed}" = "1" ]; then
  log "payload updated -- takes effect on the NEXT boot"
else
  log "payload already matches the USB stick, nothing to do"
fi
exit 0
