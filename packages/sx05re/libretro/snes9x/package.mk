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

PKG_NAME="snes9x"
PKG_VERSION="abfc018c90799eb55b773fc46d486167d8b3c762"
PKG_SHA256="d3d2e83ea318f0de3eca285c3b2446788f4c9c891beeae1c8a8e54c6a384f8a6"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="Non-commercial"
PKG_SITE="https://github.com/snes9xgit/snes9x"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="Snes9x - Portable Super Nintendo Entertainment System (TM) emulator"
PKG_LONGDESC="Snes9x - Portable Super Nintendo Entertainment System (TM) emulator"

PKG_IS_ADDON="no"
PKG_TOOLCHAIN="make"
PKG_AUTORECONF="no"

make_target() {
  if [ "${ARCH}" == "arm" ]; then
    CXXFLAGS="${CXXFLAGS} -DARM"
  fi
  
   if ([ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "OdroidGoAdvance" ]) && [ "${ARCH}" == "arm" ]; then
    make -C libretro platform=classic_armv8_a35
   else
   make -C libretro
   fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp libretro/snes9x_libretro.so ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 默认改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 snes9x_libretro.so,不在主建置重编。
# ★闸门 USE_PREBUILT_CORES★:预编译仓库(build-cores workflow)会设成 no,此时「不覆写」、
# 走上面原本的源码编译流程 —— 否则会变成「预编译仓库跑这个包时又去下载自己」的循环,
# 工具链一变就永远产不出新 .so(2026-07-16 被 mame 的 9-byte "Not Found" 坐实)。
# curl 用 -f:HTTP 错误(404)直接失败,避免把错误页当成 .so 装进固件。
if [ "${USE_PREBUILT_CORES:-yes}" = "yes" ]; then
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/snes9x_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/snes9x_libretro.so || { echo "预编译核心下载失败: snes9x_libretro.so"; exit 1; }
}
fi
