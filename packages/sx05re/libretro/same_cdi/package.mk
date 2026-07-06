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

PKG_NAME="same_cdi"
PKG_VERSION="7ee1d8e9cb4307b7cd44ee1dd757e9b3f48f41d5"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/libretro/same_cdi"
# NOTE(w2xg2022): same_cdi是MAME衍生的CD-i核心，重量级(云端CI单核编译约24分)。改用
# w2xg2022/EmuELEC的prebuilt-cores预编译整包(本机完整建置验证)，主建置只下载解压、
# 不重编。工具链ABI有变需重编时到prebuilt-cores更新。
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain expat zlib flac sqlite"
PKG_LONGDESC="SAME_CDI is a libretro core to play CD-i games. This is a fork and modification of the MAME libretro core"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p "${INSTALL}"
  curl -sL --retry 3 --fail \
    https://github.com/w2xg2022/EmuELEC/releases/download/prebuilt-cores/same_cdi_prebuilt.tar.gz \
    | tar -xz -C "${INSTALL}"
  [ -f "${INSTALL}/usr/lib/libretro/same_cdi_libretro.so" ] || die "same_cdi 预编译包解压后找不到 same_cdi_libretro.so"
}
