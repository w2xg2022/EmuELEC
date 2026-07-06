################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="scummvm"
PKG_VERSION="686cdd13719b92554fa46b264c512ca7deec7a96"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/scummvm"
# NOTE(w2xg2022): scummvm是重量级核心(云端CI单核编译约33分)。改用w2xg2022/EmuELEC
# 的prebuilt-cores预编译整包(install_pkg最终布局，含.so/.info/scummvm.zip，本机完整
# 建置验证)，主建置只下载解压、不重编。工具链ABI有变需重编时到prebuilt-cores更新。
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="libretro"
PKG_SHORTDESC="ScummVM with libretro backend."
PKG_LONGDESC="ScummVM is a program which allows you to run certain classic graphical point-and-click adventure games, provided you already have their data files."
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p "${INSTALL}"
  curl -sL --retry 3 --fail \
    https://github.com/w2xg2022/EmuELEC/releases/download/prebuilt-cores/scummvm_prebuilt.tar.gz \
    | tar -xz -C "${INSTALL}"
  [ -f "${INSTALL}/usr/lib/libretro/scummvm_libretro.so" ] || die "scummvm 预编译包解压后找不到 scummvm_libretro.so"
}
