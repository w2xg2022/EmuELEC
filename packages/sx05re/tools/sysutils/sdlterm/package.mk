# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025-present EmuELEC (https://github.com/EmuELEC)

PKG_NAME="sdlterm"
PKG_VERSION="v1"
PKG_LICENSE="Public Domain"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_ttf"
PKG_SHORTDESC="simple SDL2 program to read output of bash scripts"
PKG_TOOLCHAIN="manual"

make_target() {
  # NOTE(w2xg2022): 原本裸用sdl2-config會抓到主機系統的(不是交叉編譯sysroot裡的)，
  # 把/usr/include塞進編譯參數，直接讓cc1plus internal compiler error崩潰。
  # 仿sundog/jzintv等套件的作法，明確指向SYSROOT_PREFIX裡的sdl2-config。
    ${CXX} sdlterm.cpp -o sdlterm `${SYSROOT_PREFIX}/usr/bin/sdl2-config --cflags --libs` -lSDL2_ttf -pthread
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp sdlterm ${INSTALL}/usr/bin
}
