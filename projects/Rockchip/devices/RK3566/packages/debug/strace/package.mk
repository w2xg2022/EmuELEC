# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 w2xg2022

# strace 从全局的 6.1 提到 6.6。
#
# 原因:6.1(2022)配 6.6 内核头文件编不过——
#   src/xlat/btrfs_key_types.h:167: error: 'BTRFS_EXTENT_REF_V0_KEY' undeclared
# 那个宏在新内核的 btrfs.h 里已被移除,而 6.1 直接引用它。
#
# 6.6 上游已修:改成
#   #if defined(BTRFS_EXTENT_REF_V0_KEY) || (defined(HAVE_DECL_...) && ...)
#   ...
#   # define BTRFS_EXTENT_REF_V0_KEY 180      ← 头文件没有时自己兜底
# 所以升版即可,不需要我们自己硬补常数。
#
# 只对 MD1000 生效;其它机型走 4.19/5.15 的旧头文件,全局的 6.1 仍可编。

PKG_NAME="strace"
PKG_VERSION="6.6"
PKG_SHA256="421b4186c06b705163e64dc85f271ebdcf67660af8667283147d5e859fc8a96c"
PKG_LICENSE="BSD"
PKG_SITE="https://strace.io/"
PKG_URL="https://strace.io/files/${PKG_VERSION}/strace-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="strace is a diagnostic, debugging and instructional userspace utility"
# 用 tarball 自带的 configure,**不要**重跑 autoreconf。
#
# 全局那份 6.1 写的是 "autotools"(会先跑 scripts/autoreconf)。6.6 这样跑会坏:
# 重新生成的 configure 没带上 m4/ax_code_coverage.m4 里的 AX_CODE_COVERAGE,
# 于是 Makefile.in 里的 @CODE_COVERAGE_RULES@ 没人替换,原样留在生成的
# Makefile 第 1058 行 → make 报 "missing separator. Stop."
# tarball 自带的 configure 是上游用完整 autoconf-archive 生成的,直接用就正常。
PKG_TOOLCHAIN="configure"

# ★--enable-bundled=yes:用 strace 自带的内核头文件,不去对系统那份★
#
# 2026-08-02 云编译第四轮栽在这(163/577):
#   io_uring.c:567: error: static assertion failed:
#     "Unexpected size of arg.resv (sizeof(uint64_t) * 3 expected).
#      --enabled-bundled=yes configure option may be used to work around that."
#   (上游讯息里的 --enabled-bundled 是错字,真正的选项叫 --enable-bundled,
#    取值 yes|no|check,意思是「是否使用 bundled linux kernel headers」。)
# io_uring 的结构在 6.6 之后改过,strace 6.6 的静态断言写死了旧版布局。
#
# ★这是同一个模式的第二次★:上面记的 6.1 配 6.6 头文件挂(btrfs 常数被移除)
# 才提到 6.6;现在 6.6 配 6.18 头文件又挂。与其一路追版本(6.18 太新,
# strace 未必跟得上),不如让它用自带的头文件 —— 上游本来就为此提供了这个开关。
# 副作用:它认得的 syscall/结构以 bundled 头文件为准,对除错工具而言可接受。
#
# ★VM 上不会重现★:strace 的 stamp 是 7/28 建的(换 6.18 内核之前),之后从未重编。
PKG_CONFIGURE_OPTS_TARGET="--enable-bundled=yes"

if [ "${TARGET_ARCH}" = x86_64 -o "${TARGET_ARCH}" = "aarch64" ]; then
  PKG_CONFIGURE_OPTS_TARGET+=" --enable-mpers=no"
fi
