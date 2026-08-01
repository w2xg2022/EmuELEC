# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 w2xg2022

# 只负责把 Mali-G52 的 g24p0 GLES blob 弄下来,不自己安装任何东西。
# 由同层的 libmali 包在 post_unpack() 里用 ${SCRIPTS}/get 取用,
# 这是树里既有的模式(见 packages/linux/package.mk 抓 exfat-linux 那段)。
#
# 为什么不用 r16p0:
#   EmuELEC 原本的 packages/graphics/libmali 是 LibreELEC 那份,只有 r16p0(2019),
#   与 4.19 BSP 里的 r16p0 kbase 配套。MD1000 换到 6.6 vendor BSP 后 kbase 是
#   g25p0(2024),隔了约五年,用户空间必须跟上。
#   参照点:ROCKNIX 在同一块 MD1000 上用的就是 g24p0(实机跑得起来)。
#
# 为什么用 .deb 而不是整个仓库:
#   JeffyCN/ROCKNIX 的 libmali 仓库存了上百颗 blob,压缩包非常大(实测 12 秒才下
#   19MB 还没完);官方 release 里有按变体切分的 .deb,单个只有 ~18MB。
#
# 变体选择:EmuELEC 是 GBM/KMS(DISPLAYSERVER="no"),所以取 -gbm 而不是
#   -wayland-gbm(ROCKNIX 因为跑 sway 才用 wayland 那颗)。

PKG_NAME="libmali-g52-blob"
PKG_VERSION="v1.9-1-20260312-bd33ee2"
PKG_SHA256="1e131fef2d70a01ff89cb2511896ad735e38e1de39dd2c7d6285620f34d91d09"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/tsukumijima/libmali-rockchip"
PKG_URL="${PKG_SITE}/releases/download/${PKG_VERSION}/libmali-bifrost-g52-g24p0-gbm_1.9-1_arm64.deb"
PKG_SOURCE_NAME="libmali-bifrost-g52-g24p0-gbm_1.9-1_arm64.deb"
PKG_LONGDESC="Mali-G52 g24p0 GLES/EGL/GBM user-space blob (source only)"
PKG_TOOLCHAIN="manual"

# 这个包不产出任何东西,只是把 .deb 放进 ${SOURCES}
unpack() {
  :
}

make_target() {
  :
}

makeinstall_target() {
  :
}
