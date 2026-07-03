# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="configtools"
PKG_VERSION="28ea239c53a2d5d8800c472bc2452eaa16e37af2"
#PKG_SHA256="d89be2c5a06d45e4a8731404cd6eb52ddde393480a56754a68b44f36753e38d7"
PKG_LICENSE="GPL"
PKG_SITE="http://git.savannah.gnu.org/cgit/config.git"
# NOTE(w2xg2022): git.savannah.gnu.org的cgit snapshot網址持續回400(GitHub Actions
# runner實測確認)，改用VM本地已快取驗證過的原始碼(78KB)直接鏡像進repo。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/devel/configtools/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST=""
PKG_LONGDESC="configtools"
PKG_TOOLCHAIN="manual"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/configtools
  cp config.* ${TOOLCHAIN}/configtools
}
