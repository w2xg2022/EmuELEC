# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="sbc"
PKG_VERSION="2.0"
PKG_SHA256="8f12368e1dbbf55e14536520473cfb338c84b392939cc9b64298360fd4a07992"
PKG_LICENSE="GPL"
PKG_SITE="http://www.bluez.org/"
# NOTE(w2xg2022): kernel.org回404，改用repo內自帶鏡像(源碼取自VM本地sources/
# 快取，sha256驗證跟本檔案記錄的完全一致，正版原始檔案)。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/audio/sbc/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="standalone SBC library"
PKG_BUILD_FLAGS="+pic"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-tools \
                           --disable-tester"

post_makeinstall_target() {
  # fix static library
  sed -i 's/-lsbc/-lsbc -lbluetooth/' ${SYSROOT_PREFIX}/usr/lib/pkgconfig/sbc.pc
}
