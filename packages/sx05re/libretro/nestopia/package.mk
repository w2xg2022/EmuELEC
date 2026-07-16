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

PKG_NAME="nestopia"
PKG_VERSION="e9429844f2e16a284a8cdf663589634fd4c6345f"
PKG_SHA256="5d145e4171bd3381def8ba6d4f08a79d04d3a09c0d53e0b89266b7aa89402990"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/nestopia"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_PRIORITY="optional"
PKG_SECTION="libretro"
PKG_SHORTDESC="Libretro implementation of NEStopia. (Nintendo Entertainment System)"
PKG_LONGDESC="This project is a fork of the original Nestopia source code, plus the Linux port. The purpose of the project is to enhance the original, and ensure it continues to work on modern operating systems."

PKG_IS_ADDON="no"
PKG_TOOLCHAIN="make"
PKG_AUTORECONF="no"
PKG_USE_CMAKE="no"

make_target() {
  cd ${PKG_BUILD}
  make -C libretro
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp libretro/nestopia_libretro.so ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 nestopia_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/nestopia_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/nestopia_libretro.so || { echo "预编译核心下载失败: nestopia_libretro.so"; exit 1; }
}
