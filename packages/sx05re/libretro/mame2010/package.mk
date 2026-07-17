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

PKG_NAME="mame2010"
PKG_VERSION="c5b413b71e0a290c57fc351562cd47ba75bac105"
PKG_SHA256="38270732ef2b503583e96a3c83cd5ba8d4ca6510d1f24f2b00bf6703eb74070d"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/libretro/mame2010-libretro"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="Late 2010 version of MAME (0.139) for libretro. Compatible with MAME 0.139 romsets."
PKG_LONGDESC="Late 2010 version of MAME (0.139) for libretro. Compatible with MAME 0.139 romsets."

PKG_IS_ADDON="no"
PKG_TOOLCHAIN="make"
PKG_AUTORECONF="no"

# ★源码编译逻辑(上游原版)——必须保留★
# USE_PREBUILT_CORES=no 时走这条,让 w2xg2022/EmuELEC-prebuilt-cores 仓库能真的「从源码」编出 .so。
# 若把这条删掉(只留下面的下载覆写),预编译仓库跑本包时就变成「下载自己」的循环——
# 2026-07-16 实际踩到:仓库改名那刻 releases/latest 还是空的 → 404 → 当时的 curl 没带 -f,
# 把 9 bytes 的 "Not Found" 当成 .so 上传成「预编译核心」,固件里的 MAME 直接变成文本档。
make_target() {
  if [ "${ARCH}" == "arm" ]; then
    make CC="${CC}" LD="${CC}" PLATCFLAGS="${CFLAGS}" PTR64=0 ARM_ENABLED=1 LCPU=arm
  elif [ "${ARCH}" == "i386" ]; then
    make CC="${CC}" LD="${CC}" PLATCFLAGS="${CFLAGS}" PTR64=0 ARM_ENABLED=0 LCPU=x86
  elif [ "${ARCH}" == "x86_64" ]; then
    make CC="${CC}" LD="${CC}" PLATCFLAGS="${CFLAGS}" PTR64=1 ARM_ENABLED=0 LCPU=x86_64
  elif [ "${ARCH}" == "aarch64" ]; then
    make CC="${CC}" LD="${CC}" PLATCFLAGS="${CFLAGS}" PTR64=1 ARM_ENABLED=1 LCPU=arm64 maketree
    make CC="${CC}" LD="${CC}" PLATCFLAGS="${CFLAGS}" PTR64=1 ARM_ENABLED=1 LCPU=arm64
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mame2010_libretro.so ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# 默认改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 .so,不在主建置(尤其云端 CI 磁盘有限)
# 重编这个重量级核心。★闸门★:预编译仓库会设 USE_PREBUILT_CORES=no,此时不覆写、走上面的
# 源码编译。curl 用 -f:HTTP 错误(404)直接让建置失败,绝不把错误页当成 .so 装进固件。
if [ "${USE_PREBUILT_CORES:-yes}" = "yes" ]; then
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/mame2010_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/mame2010_libretro.so \
    || { echo "预编译核心下载失败: mame2010_libretro.so"; exit 1; }
}
fi
