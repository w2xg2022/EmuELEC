# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="libtool"
PKG_VERSION="2.4.7"
PKG_SHA256="04e96c2404ea70c590c546eba4202a4e12722c640016c12b9b2f1ce3d481e9a8"
PKG_LICENSE="GPL"
PKG_SITE="http://www.gnu.org/software/libtool/"
PKG_URL="https://ftp.gnu.org/gnu/libtool/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="ccache:host autoconf:host automake:host intltool:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A generic library support script."
# NOTE(w2xg2022): 2026-08-02 从 2.4.6 提到 2.4.7。
#
# 2.4.6(2015) 配 automake 1.16.5 的 autoreconf 会挂:
#   automake: error: cannot open < libltdl/ltdl.mk: No such file or directory
# 2.4.6 提供的是 libltdl/Makefile.inc,而这个版本的 automake 期待 ltdl.mk;
# 2.4.7 已改名(实测:2.4.7 有 ltdl.mk、没有 Makefile.inc)。
#
# ★不能改用 tarball 自带的 configure 绕过★:patches/ 里的
# libtool-03-remove-help2man-dependency 改的是 Makefile.am,
# 不重跑 autoreconf 那个 patch 等于没改。
#
# ★同时删掉 libtool-02-use_ld.patch★:它给 ltmain.sh 的旗标白名单加 -fuse-ld=*,
# 而 2.4.7 上游已经内建(build-aux/ltmain.sh:7564,注解 Linker select flags for GCC),
# 套用会 Hunk FAILED。另两个 patch 已实地依序试套确认 APPLIED。
#
# 云编译第五轮(176/577)栽在这。VM 不重现:libtool 的 stamp 是 7/27 建的。
# (顺带更正一条旧结论:记忆里写「runner 必用 22.04,24.04 会让 libtool 挂」——
#  本次 build job 确实跑在 ubuntu-22.04 却照样挂,而且 autoreconf 用的是
#  【工具链自己的】automake 不是系统的,所以 host OS 版本本来就不是关键。)

# ★PKG_TOOLCHAIN 从 autotools 改成 configure(2026-08-02)★
# autotools 会跑 autoreconf -> libtoolize,而工具链里那支 libtoolize 是
# 【上一次建置留下的旧版】。用 2.4.6 的 libtoolize 处理 2.4.7 的原始码时,
# 它会把 2.4.7 自带的 libltdl/ltdl.mk 洗掉 -> automake 报
#   cannot open < libltdl/ltdl.mk: No such file or directory
# 典型 bootstrap 鸡生蛋(要建 2.4.7 得先有 2.4.7 的 libtoolize)。
# tarball 自带的 configure/Makefile.in 是上游用完整 autotools 生成的,直接用即可;
# 两个 patch 都已改成只动自带档(ltmain.sh / Makefile.in),不需要重新生成。
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_HOST="--enable-static --disable-shared"

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
  rm -rf ${INSTALL}/usr/share
}
