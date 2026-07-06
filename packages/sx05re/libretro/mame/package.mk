# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019 Trond Haugland (trondah@gmail.com)

PKG_NAME="mame"
PKG_VERSION="6cdc40fc53ba5574073d4009b531fda07156ff49"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mame"
# NOTE(w2xg2022): 完整版mame是整个建置里最重的单一套件(实测云端CI单核编译2-3小时、
# 源码/内存/磁盘消耗巨大，是平行编译时间的绝对瓶颈)。改用w2xg2022/EmuELEC-MAME
# 预编译好的整包(mame_libretro.so + hiscore/hash/config等资料档的最终安装布局，
# 已在本机完整建置验证)，主建置只下载解压、完全不重编。若mame本体或工具链ABI有变
# 需要重编，到EmuELEC-MAME仓库手动触发rebuild再更新这里。
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain zlib flac sqlite expat"
PKG_SECTION="libretro"
PKG_SHORTDESC="MAME - Multiple Arcade Machine Emulator"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p "${INSTALL}"
  # 预编译整包内容是 ./usr/... 的最终安装布局，直接解压进 ${INSTALL}
  curl -sL --retry 3 --fail \
    https://github.com/w2xg2022/EmuELEC-MAME/releases/latest/download/mame_libretro_prebuilt.tar.gz \
    | tar -xz -C "${INSTALL}"
  # 确认关键档案有解出来，避免静默产出空壳
  [ -f "${INSTALL}/usr/lib/libretro/mame_libretro.so" ] || die "mame 预编译包解压后找不到 mame_libretro.so"
}
