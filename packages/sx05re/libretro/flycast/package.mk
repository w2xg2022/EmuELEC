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

PKG_NAME="flycast"
PKG_VERSION="$(get_pkg_version flycastsa)"
PKG_NEED_UNPACK="$(get_pkg_directory flycastsa)"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain ${OPENGLES}"
PKG_SHORTDESC="Flycast is a multiplatform Sega Dreamcast emulator"
PKG_BUILD_FLAGS="-lto"
PKG_TOOLCHAIN="cmake"

PKG_CMAKE_OPTS_TARGET="-DLIBRETRO=ON \
                        -DUSE_OPENMP=OFF \ 
                        -DCMAKE_BUILD_TYPE=Release \
                        -DUSE_GLES2=OFF \
                        -DUSE_GLES=ON \
                        -DUSE_VULKAN=OFF"

pre_make_target() {
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  if [ "${ARCH}" == "arm" ]; then
	cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/flycast_32b_libretro.so
  else
	cp flycast_libretro.so ${INSTALL}/usr/lib/libretro/
  fi
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 flycast_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/flycast_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/flycast_libretro.so || { echo "预编译核心下载失败: flycast_libretro.so"; exit 1; }
}
