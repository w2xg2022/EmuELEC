# SPDX-License-Identifier: GPL-3.0-or-later

PKG_NAME="emuscv"
PKG_VERSION="dfce10df090ce3f5eb23bdbee289702ec1478246"
PKG_SHA256=""
PKG_LICENSE="GPL-3.0-or-later"
PKG_SITE="https://gitlab.com/MaaaX-EmuSCV/libretro-emuscv"
PKG_URL="${PKG_SITE}.git"

PKG_ARCH="any"
PKG_SECTION="emuelec/libretro"
PKG_DEPENDS_TARGET="toolchain SDL2 zlib"
PKG_SHORTDESC="EmuSCV libretro core"
PKG_TOOLCHAIN="make"
PKG_GIT_CLONE_SINGLE="yes"

pre_make_target() {
  export PATH="${SYSROOT_PREFIX}/usr/bin:${PATH}"
  mkdir -p sys
  : > sys/io.h
  sed -i 's|-I/usr/include/SDL2||g' Makefile.libretro

# NOTE(w2xg2022): Makefile.libretro的build/clean/rebuild target都把cls
# (單純@clear清畫面，跟編譯結果無關)當前置依賴，雲端CI環境沒有可用的TERM，
# clear指令直接非零結束，整個建置就中止在這個純裝飾性的步驟上(GitHub
# Actions runner實測確認)。把cls的recipe中和成no-op，不影響實際編譯內容。
  sed -i '/^cls:$/,/^\t@clear$/ s|^\t@clear$|\t@:|' Makefile.libretro
}

make_target() {
  make -f Makefile.libretro platform=unix \
    CC="${CC}" CXX="${CXX}" AR="${AR}" RANLIB="${RANLIB}" STRIP="${STRIP}"
}

makeinstall_target() {
  mkdir -p "${INSTALL}/usr/lib/libretro"
  cp emuscv_libretro.so "${INSTALL}/usr/lib/libretro/"
}
