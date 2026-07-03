# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2020-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="rtmpdump"
PKG_VERSION="c5f04a58fc2aeea6296ca7c44ee4734c18401aa3"
PKG_SHA256="ac928cdde9c1ae77a65f924bed4831d98645ae8807ab63eaf6478022d9771a05"
PKG_LICENSE="GPL"
PKG_SITE="http://rtmpdump.mplayerhq.hu/"
# NOTE(w2xg2022): git.ffmpeg.org常態性502(GitHub Actions runner多次實測確認，
# 跟連線無關，是官方伺服器本身不穩)。VM本地快取過這個commit的原始碼，改把
# 這份驗證過的原始碼(139KB)直接打包commit進repo，用raw.githubusercontent.com
# 取代失效的git來源。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/multimedia/rtmpdump/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain zlib openssl"
PKG_LONGDESC="rtmpdump is a toolkit for RTMP streams."
PKG_BUILD_FLAGS="+pic"

make_target() {
  make prefix=/usr \
       incdir=/usr/include/librtmp \
       libdir=/usr/lib \
       mandir=/usr/share/man \
       CC="${CC}" \
       LD="${LD}" \
       AR="${AR}" \
       SHARED=no \
       CRYPTO="OPENSSL" \
       OPT="" \
       XCFLAGS="${CFLAGS}" \
       XCFLAGS="${CFLAGS} -Wno-unused-but-set-variable -Wno-unused-const-variable" \
       XLDFLAGS="${LDFLAGS}" \
       XLIBS="-lm"
}

makeinstall_target() {
  make DESTDIR=${SYSROOT_PREFIX} \
       prefix=/usr \
       incdir=/usr/include/librtmp \
       libdir=/usr/lib \
       mandir=/usr/share/man \
       CC="${CC}" \
       LD="${LD}" \
       AR="${AR}" \
       SHARED=no \
       CRYPTO="OPENSSL" \
       OPT="" \
       XCFLAGS="${CFLAGS}" \
       XLDFLAGS="${LDFLAGS}" \
       XLIBS="-lm" \
       install

  make DESTDIR=${INSTALL} \
       prefix=/usr \
       incdir=/usr/include/librtmp \
       libdir=/usr/lib \
       mandir=/usr/share/man \
       CC="${CC}" \
       LD="${LD}" \
       AR="${AR}" \
       SHARED=no \
       CRYPTO="OPENSSL" \
       OPT="" \
       XCFLAGS="${CFLAGS}" \
       XLDFLAGS="${LDFLAGS}" \
       XLIBS="-lm" \
       install
}

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/sbin

#  # to be removed: hack for "compatibility"
#  mkdir -p ${INSTALL}/usr/lib
#    ln -sf librtmp.so.1 ${INSTALL}/usr/lib/librtmp.so.0
}
