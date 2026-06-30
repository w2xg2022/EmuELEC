# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="applewin"
PKG_VERSION="f2c22675385a5c2561d7aec1cc8ecf860e20fc5d"
PKG_SHA256="365e262ed145b23cd79a9365cfab47c5d7b5e1625e867d337b534267a4c916fb"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/audetto/AppleWin"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="libretro"
PKG_SHORTDESC="libretro core for Apple II emulation (AppleWin libretro fork)"
PKG_TOOLCHAIN="cmake"

# NOTE(w2xg2022): repo原本只有applewin_libretro.info沒有實際.so，
# apple2系統預設指定的mame core也沒有編譯出.so(只有.info)，apple2完全玩不了。
# audetto/AppleWin是libretro官方推荐的apple2 core來源，BUILD_LIBRETRO是
# 唯一不需要Qt5/Boost的build選項(只有BUILD_QAPPLE才需要那些)。
pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO=ON -DBUILD_QAPPLE=OFF -DBUILD_SA2=OFF -DBUILD_APPLEN=OFF"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/source/frontends/libretro/applewin_libretro.so ${INSTALL}/usr/lib/libretro/
}
