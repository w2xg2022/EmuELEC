# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present Team CoreELEC (https://coreelec.org)

PKG_NAME="aml-w155s2-bt-firmware"
PKG_VERSION="x98mini"
PKG_LICENSE="nonfree"
PKG_SITE="https://coreelec.org"
PKG_LONGDESC="Amlogic W155S2 (W1 combo) Bluetooth UART firmware, used by the hci_aml driver."
PKG_TOOLCHAIN="manual"

# The firmware blob is shipped inside this package (see firmware/); there is no
# PKG_URL, nothing is fetched at build time.
#
# NOTE: this is NOT the upstream linux-firmware amlogic/aml_w155s2_bt_uart.bin.
# That blob is a different firmware revision that the X98mini's W1 controller
# downloads happily but then fails to run (silent after start_chip). The blob
# here was extracted from the box's own Android vendor libbt-vendor_aml.so
# (bt_fucode.h: iccm + dccm) and repacked into the [iccm_len][dccm_len][256K
# pad][iccm][dccm] layout the hci_aml driver expects. This is the firmware the
# chip actually boots with. sha256 21cf3852478e41c4e4bfb41840a596d62a18b1cfe9c8b7e507cd3c394becbfdc

makeinstall_target() {
  FWDIR="${INSTALL}/$(get_full_firmware_dir)/amlogic"

  mkdir -p "${FWDIR}"
    cp -a "${PKG_DIR}/firmware/aml_w155s2_bt_uart.bin" "${FWDIR}"
}
