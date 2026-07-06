# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="scummvmsa"
PKG_VERSION="0d62e946497ec9fc432750734e94a7333db0963c"
PKG_REV="1"
PKG_LICENSE="GPL2"
PKG_SITE="https://github.com/scummvm/scummvm"
# NOTE(w2xg2022): 独立版scummvm是重量级核心(云端CI单核编译约29分)。改用w2xg2022/
# EmuELEC的prebuilt-cores预编译整包(install_pkg最终布局，含usr/bin/scummvm二进制、
# usr/local/share/scummvm/*.dat资料档、usr/config/scummvm设定，本机完整建置验证)，
# 主建置只下载解压、不重编。工具链ABI有变需重编时到prebuilt-cores更新。
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_net freetype fluidsynth-git libmad timidity"
PKG_SHORTDESC="Script Creation Utility for Maniac Mansion Virtual Machine"
PKG_LONGDESC="ScummVM is a program which allows you to run certain classic graphical point-and-click adventure games, provided you already have their data files."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p "${INSTALL}"
  curl -sL --retry 3 --fail \
    https://github.com/w2xg2022/EmuELEC/releases/download/prebuilt-cores/scummvmsa_prebuilt.tar.gz \
    | tar -xz -C "${INSTALL}"
  [ -f "${INSTALL}/usr/bin/scummvm" ] || die "scummvmsa 预编译包解压后找不到 usr/bin/scummvm"
}
