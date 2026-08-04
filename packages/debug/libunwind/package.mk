# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libunwind"
PKG_VERSION="1.6.2"
PKG_SHA256="4a6aec666991fb45d0889c44aede8ad6eb108071c3554fcdff671f9c94794976"
PKG_LICENSE="GPL"
PKG_SITE="http://www.nongnu.org/libunwind/"
PKG_URL="https://github.com/libunwind/libunwind/releases/download/v${PKG_VERSION}/libunwind-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain zlib"
PKG_LONGDESC="library to determine the call-chain of a program"
PKG_BUILD_FLAGS="+pic"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-minidebuginfo \
                           --disable-documentation \
                           --disable-tests"

# NOTE(w2xg2022 2026-08-04): ★重新产生 autotools 档, 否则 libtool 版本对不上编不过★
#
#   libunwind-1.6.2 的 tarball 里, configure / aclocal.m4 是用 **libtool 2.4.6** 产的,
#   而本树的工具链提供的是 **2.4.7**, 於是一编就死在:
#       libtool: Version mismatch error. This is libtool 2.4.7, but the
#       libtool: definition of this LT_INIT comes from libtool 2.4.6.
#       FAILURE: scripts/build libunwind:target during make_target
#
#   ★这与接力 checkpoint 的新旧无关★: 实机 2026-08-04 用 clean_pkgs 把 build/.stamps/
#   install_pkg 全清掉、从 tarball 重新解开, 结果一模一样 —— 是这个 tarball 本身与
#   现在的 libtool 不相容。(先前误判成「旧工具链世代的半成品」, 清了才知道不是。)
#
#   ⚠️ 之所以拖到现在才爆: 各机型的 checkpoint 里 libunwind 早就装好了, 没人去重编它。
#      哪天 MD1000 的 checkpoint 被清掉或 libunwind 被 invalidate, 它一样会中 ——
#      所以修在套件本身, 不是修在某一台的 workflow 参数。
pre_configure_target() {
  do_autoreconf
}

makeinstall_target() {
  make DESTDIR=${SYSROOT_PREFIX} install
}
