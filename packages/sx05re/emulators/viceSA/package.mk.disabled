# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="viceSA"
PKG_VERSION="3.3"
PKG_SHA256="1a55b38cc988165b077808c07c52a779d181270b28c14b5c9abf4e569137431d"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL2"
PKG_SITE="https://freefr.dl.sourceforge.net/project/vice-emu/releases"
# NOTE(w2xg2022): freefr.dl.sourceforge.net這個特定鏡像節點連線逾時(GitHub
# Actions runner實測確認)，改用VM本地已驗證的原始碼(22MB，SHA256完全吻合)
# 直接鏡像進repo，繞開這個不穩定的鏡像節點。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/sx05re/emulators/viceSA/vice-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain SDL2 SDL2_mixer SDL2_ttf xa:host ffmpeg"
PKG_LONGDESC="VICE is an emulator collection which emulates the C64, the C64-DTV, the C128, the VIC20, practically all PET models, the PLUS4 and the CBM-II (aka C610)."
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET=" --enable-external-ffmpeg --disable-option-checking --enable-midi --enable-lame --with-zlib --with-jpeg --with-png --enable-x64"

pre_configure_target() {
	LDFLAGS="${LDFLAGS} -lSDL2"
}
