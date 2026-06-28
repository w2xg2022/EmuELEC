# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present w2xg2022

# NOTE(w2xg2022): Skyworth E900V22C(g12a/S905X2)專屬dtb。
# 原生dts(g12a_s905x2_2g_e900v22c.dts)透過patches/linux/0002-e900v22c-add-dts.patch
# 加進linux kernel原始碼正常編譯，內容來自KryptonLee/e900v22c-CoreELEC反編譯校正
# (已修正uwe5621ds WiFi/藍牙晶片的PWM時脈設定)，不是套用預編譯二進位blob。
# bootloader/mkimage會在SUBDEVICE!=Generic時找${SUBDEVICE}_dtb.img替換掉預設dtb.img，
# 不需要自訂u-boot，沿用Amlogic-ng Generic既有的u-boot/開機鏈即可。

PKG_NAME="e900v22c-dtb"
PKG_VERSION="1.0"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/KryptonLee/e900v22c-CoreELEC"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain linux"
PKG_LONGDESC="Skyworth E900V22C device tree (uwe5621ds WiFi/BT PWM clock fix)"
PKG_IS_ADDON="no"
PKG_TOOLCHAIN="manual"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader
  cp "$(get_build_dir linux)/arch/arm64/boot/dts/amlogic/g12a_s905x2_2g_e900v22c.dtb" \
     ${INSTALL}/usr/share/bootloader/E900V22C_dtb.img
}
