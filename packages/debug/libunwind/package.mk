# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libunwind"
PKG_VERSION="1.6.2"
PKG_SHA256="4a6aec666991fb45d0889c44aede8ad6eb108071c3554fcdff671f9c94794976"
PKG_LICENSE="GPL"
PKG_SITE="http://www.nongnu.org/libunwind/"
PKG_URL="https://github.com/libunwind/libunwind/releases/download/v${PKG_VERSION}/libunwind-${PKG_VERSION}.tar.gz"
# NOTE(w2xg2022 2026-08-04): ★libtool:host 必须列进来 —— 少了它会【静默】编出错配的树★
#
#   本树对 PKG_TOOLCHAIN="autotools" 的套件会自动跑 autoreconf(scripts/build ->
#   scripts/autoreconf -> do_autoreconf)。但 do_autoreconf 里有这道守衛:
#       if [ -e "$LIBTOOLIZE" ]; then AUTORECONF="... --install"; else AUTORECONF="..."; fi
#   工具链的 libtool 若还没编出来, ${LIBTOOLIZE} 不存在 -> ★不加 --install★ ->
#   libtoolize 那一步整个跳过 -> config/ltmain.sh 仍是 tarball 里的(libtool 2.4.6),
#   而 aclocal 拉进来的巨集已经是 2.4.7 -> 编到一半死在:
#       libtool: Version mismatch error. This is libtool 2.4.7, but the
#       libtool: definition of this LT_INIT comes from libtool 2.4.6.
#
#   ★这是顺序问题, 不是套件坏掉★: 平行建置时 libunwind 可能排在 libtool 之前。
#   实机 2026-08-04 的两轮对照坐实 —— 同一份原始码, 第一轮没有 libtoolize 那一步而失败,
#   下一轮(libtool 已经编好了)就有 libtoolize、错配随之消失。
#   ⚠️ 那道守衛失败时【不报错也不警告】, 只是默默降级成弱版 autoreconf,
#      所以现象看起来像「这个 tarball 有问题」, 很容易往错的方向修。
PKG_DEPENDS_TARGET="toolchain zlib libtool:host"
PKG_LONGDESC="library to determine the call-chain of a program"
PKG_BUILD_FLAGS="+pic"
PKG_TOOLCHAIN="autotools"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --disable-shared \
                           --disable-minidebuginfo \
                           --disable-documentation \
                           --disable-tests"

# NOTE(w2xg2022 2026-08-04): ★删掉 tarball 自带的 aclocal.m4, 否则 LT_INIT 永远是旧的★
#
#   补了 libtool:host 之后 libtoolize 确实跑了、config/ltmain.sh 换成 2.4.7,
#   但编译还是死在同一句版本错配 —— 因为 aclocal.m4 里的 LT_INIT 仍是 2.4.6 的。
#   libtoolize 自己在日志里就讲了:
#       libtoolize: You should add the contents of the following files to 'aclocal.m4':
#       libtoolize:   .../toolchain/share/aclocal/libtool.m4
#       libtoolize:   .../toolchain/share/aclocal/ltversion.m4
#       libtoolize: Consider adding 'AC_CONFIG_MACRO_DIRS([m4])' to configure.ac
#   libunwind-1.6.2 的 configure.ac 没有 AC_CONFIG_MACRO_DIRS, 所以 aclocal 不会去
#   动那份【随 tarball 附带、用 2.4.6 产生的】aclocal.m4 —— 於是 ltmain.sh(2.4.7) 与
#   LT_INIT(2.4.6) 各说各话, 一编就炸。
#
#   把它删掉, autoreconf 就会用工具链搜寻路径里的 2.4.7 巨集重新产生一份, 两边对齐。
#   ★用 post_unpack 而不是 pre_build★: scripts/build 是【先】autoreconf(第222行)
#   才呼叫 pre_build_target(第228行), 在 pre_build 里删已经来不及。
post_unpack() {
  rm -f ${PKG_BUILD}/aclocal.m4
}

makeinstall_target() {
  make DESTDIR=${SYSROOT_PREFIX} install
}
