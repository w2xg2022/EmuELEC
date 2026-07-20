# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present w2xg2022

# NOTE(w2xg2022): Skyworth E900V22C(S905L3A/g12a)專屬dtb —— no線(5.15)版本。
#
# 跟ng線(4.9)那個同名package不同，這裡裝的是CoreELEC-22 Piers nightly的
# **預編vendor dtb**(g12a_s905x2_2g.dtb)，不是自己從dts源碼編的。理由：
#   1. 記憶 e900v22c-5-15-adaptation 的鐵律：vendor內核+vendor dtb+vendor驅動
#      三件套要整套配對，這顆正是corebian在同一顆5.15.196上實機驗證過
#      WiFi+藍牙都能跑的那顆(boards/e900v22c/dtb.img，sha256 666cd1e0…)。
#   2. EmuELEC自己編的g12a_s905x2_2g.dtb跟它反編譯後差1093行(時脈設定、
#      clk_level、節點okay/disabled都不同)，等於是沒驗證過的另一顆，不能替代。
#   3. 倉庫裡那份自訂的g12a_s905x2_2g_e900v22c.dts(KryptonLee反編譯校正、
#      含uwe5621ds PWM時脈修正)是ng線4.9驗證的產物，在5.15上未經實測。
#      dts patch留著不動(照樣編出dtb進device_trees)，只是開機不用它。
#      等這顆先跑通，再回頭評估自訂dts在5.15有沒有額外好處。
#
# subdevice_config.sh 的 DEVICE_DTB 指向這裡裝出來的 E900V22C_dtb.img。

PKG_NAME="e900v22c-dtb"
PKG_VERSION="1.0"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/CoreELEC/CoreELEC"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Skyworth E900V22C vendor device tree (CoreELEC-22 prebuilt, WiFi/BT verified)"
PKG_IS_ADDON="no"
PKG_TOOLCHAIN="manual"

make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/share/bootloader
  cp ${PKG_DIR}/dtb/E900V22C_dtb.img ${INSTALL}/usr/share/bootloader/E900V22C_dtb.img
}
