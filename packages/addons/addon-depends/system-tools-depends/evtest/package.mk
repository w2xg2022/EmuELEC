# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="evtest"
PKG_VERSION="7cfe0a95e0db6043c6445cb9120215902c3b9b74"
PKG_SHA256="a224abeb783561193660999b0c986216d691cb271b5ec3af88c6bb37b55ff51c"
PKG_LICENSE="GPL"
PKG_SITE="http://cgit.freedesktop.org/evtest/"
PKG_URL="https://gitlab.freedesktop.org/libevdev/evtest.git"
PKG_DEPENDS_TARGET="toolchain libxml2"
PKG_LONGDESC="A simple tool for input event debugging."
PKG_TOOLCHAIN="autotools"
PKG_BUILD_FLAGS="-sysroot"

make_target() {
  make evtest ${PKG_MAKE_OPTS_TARGET}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp -a evtest ${INSTALL}/usr/bin/
}
