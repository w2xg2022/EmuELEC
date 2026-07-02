# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)

PKG_NAME="xmlstarlet"
PKG_VERSION="1.6.1"
PKG_SHA256="15d838c4f3375332fd95554619179b69e4ec91418a3a5296e7c631b7ed19e7ca"
PKG_LICENSE="MIT"
PKG_SITE="http://xmlstar.sourceforge.net"
# NOTE(w2xg2022): netcologne.dl.sourceforge.net連線異常，改用repo內自帶鏡像
# (源碼取自VM本地sources/快取，sha256驗證跟本檔案記錄的完全一致，正版原始
# 檔案)。這是host端建置工具，很多套件的PKG_DEPENDS_HOST都靠它，抓不到會讓
# 整個建置崩潰，優先修好。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/textproc/xmlstarlet/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="libxml2:host libxslt:host"
PKG_DEPENDS_TARGET="toolchain libxml2 libxslt"
PKG_LONGDESC="XMLStarlet is a command-line XML utility which allows the modification and validation of XML documents."

PKG_CONFIGURE_OPTS_HOST="  ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes \
                           --enable-static-libs \
                           LIBXML_CONFIG=${TOOLCHAIN}/bin/xml2-config \
                           LIBXSLT_CONFIG=${TOOLCHAIN}/bin/xslt-config \
                           --with-libxml-include-prefix=${TOOLCHAIN}/include/libxml2 \
                           --with-libxml-libs-prefix=${TOOLCHAIN}/lib \
                           --with-libxslt-include-prefix=${TOOLCHAIN}/include \
                           --with-libxslt-libs-prefix=${TOOLCHAIN}/lib"

PKG_CONFIGURE_OPTS_TARGET="ac_cv_func_malloc_0_nonnull=yes \
                           ac_cv_func_realloc_0_nonnull=yes \
                           --enable-static-libs \
                           LIBXML_CONFIG=${SYSROOT_PREFIX}/usr/bin/xml2-config \
                           LIBXSLT_CONFIG=${SYSROOT_PREFIX}/usr/bin/xslt-config \
                           --with-libxml-include-prefix=${SYSROOT_PREFIX}/usr/include/libxml2 \
                           --with-libxml-libs-prefix=${SYSROOT_PREFIX}/usr/lib \
                           --with-libxslt-include-prefix=${SYSROOT_PREFIX}/usr/include \
                           --with-libxslt-libs-prefix=${SYSROOT_PREFIX}/usr/lib"

post_makeinstall_host() {
  ln -sf xml ${TOOLCHAIN}/bin/xmlstarlet
}

post_makeinstall_target() {
  ln -sf xml ${INSTALL}/usr/bin/xmlstarlet
}
