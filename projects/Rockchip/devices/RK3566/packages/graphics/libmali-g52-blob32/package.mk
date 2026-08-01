# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 w2xg2022

# 32 位(armhf)的 Mali-G52 g24p0 blob,给 lib32-libmali 用。
# 与 64 位那颗(libmali-g52-blob)成对,只是官方 release 没出 armhf 的 .deb,
# 所以直接取仓库里的单个 .so(按 tag 固定,sha256 已核对)。
#
# 为什么需要 32 位:EmuELEC 在 aarch64 上会编一批 32 位 libretro 核心
# (lib32-mupen64plus / lib32-flycast / lib32-parallel-n64 等),它们依赖
# lib32-${OPENGLES};OPENGLES 设成 libmali 之后就得有 lib32-libmali。

PKG_NAME="libmali-g52-blob32"
PKG_VERSION="v1.9-1-20260312-bd33ee2"
PKG_SHA256="78d4500687c47e32e4a03e306eabaf2bc1d306ac2ab250a7ad3ea2502315fe6c"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/tsukumijima/libmali-rockchip"
PKG_URL="https://raw.githubusercontent.com/tsukumijima/libmali-rockchip/${PKG_VERSION}/lib/arm-linux-gnueabihf/libmali-bifrost-g52-g24p0-gbm.so"
PKG_SOURCE_NAME="libmali-bifrost-g52-g24p0-gbm-armhf.so"
PKG_LONGDESC="Mali-G52 g24p0 GLES/EGL/GBM user-space blob, 32-bit (source only)"
PKG_TOOLCHAIN="manual"

# 只提供源文件,不产出任何东西
unpack() {
  :
}

make_target() {
  :
}

makeinstall_target() {
  :
}
