# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="fakeroot"
PKG_VERSION="1.30.1"
PKG_SHA256="32ebb1f421aca0db7141c32a8c104eb95d2b45c393058b9435fbf903dd2b6a75"
PKG_LICENSE="GPL3"
PKG_SITE="https://tracker.debian.org/pkg/fakeroot"
# NOTE(w2xg2022): ftp.debian.org回404，改用repo內自帶鏡像(源碼取自VM本地
# sources/快取，sha256驗證跟本檔案記錄的完全一致，正版原始檔案)。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/devel/fakeroot/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host libcap:host autoconf:host libtool:host"
PKG_LONGDESC="fakeroot provides a fake root environment by means of LD_PRELOAD and SYSV IPC (or TCP) trickery."
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_HOST="--with-gnu-ld"

pre_configure_host() {
  cd ${PKG_BUILD}
  ./bootstrap
}
