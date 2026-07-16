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

PKG_NAME="ppsspp"
PKG_VERSION="$(get_pkg_version PPSSPPSDL)"
PKG_NEED_UNPACK="$(get_pkg_directory PPSSPPSDL)"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="https://github.com/hrydgard/ppsspp.git"
# NOTE(w2xg2022): libglvnd會覆蓋系統libEGL.so.1/libGLESv2.so.2指向Mali的symlink，
# 導致ES/RA顯示初始化失敗，且libretro core實際沒有直接連結libOpenGL.so，拿掉。
PKG_DEPENDS_TARGET="toolchain SDL2 ffmpeg"
PKG_LONGDESC="A PSP emulator for Android, Windows, Mac, Linux and Blackberry 10, written in C++."
GET_HANDLER_SUPPORT="git"
PKG_PATCH_DIRS+=" $(get_pkg_directory PPSSPPSDL)/patches"

PKG_LIBNAME="ppsspp_libretro.so"
PKG_LIBPATH="lib/${PKG_LIBNAME}"

post_unpack() {
  ( cd "${PKG_BUILD}" && git submodule update --init --recursive )
}

pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET="-DLIBRETRO=ON \
                         -DUSE_SYSTEM_FFMPEG=ON \
                         -DUSING_X11_VULKAN=OFF"

  if [ "${ARCH}" = "arm" ] && [ ! "${TARGET_CPU}" = "arm1176jzf-s" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DARMV7=ON"
  elif [ "${TARGET_CPU}" = "arm1176jzf-s" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DARM=ON"
  fi

  if [ "${OPENGLES_SUPPORT}" = "yes" ]; then
    PKG_CMAKE_OPTS_TARGET+=" -DUSING_FBDEV=ON \
                             -DUSING_EGL=ON \
                             -DUSING_GLES2=ON"
  fi
  
if [ ${ARCH} == "aarch64" ]; then
PKG_CMAKE_OPTS_TARGET+=" -DARM64=ON"
else
PKG_CMAKE_OPTS_TARGET+=" -DARMV7=ON"
fi
  
}

pre_make_target() {
  # fix cross compiling
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_LIBPATH} ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 ppsspp_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/ppsspp_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/ppsspp_libretro.so || { echo "预编译核心下载失败: ppsspp_libretro.so"; exit 1; }
}
