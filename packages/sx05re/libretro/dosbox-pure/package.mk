# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dosbox-pure"
PKG_VERSION="fe0bdab8a04eedb912634d89ad8137de75529cff"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/schellingb/dosbox-pure"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain linux glibc glib systemd dbus alsa-lib SDL2 SDL2_net SDL_sound libpng zlib libvorbis flac libogg fluidsynth-git munt opusfile"
PKG_LONGDESC="DOSBox Pure is a new fork of DOSBox built for RetroArch/Libretro aiming for simplicity and ease of use. "
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="+lto"


pre_configure_target() {

if [ "${DEVICE}" == "Amlogic-old" ]; then
	PKG_MAKE_OPTS_TARGET=" platform=emuelec"
elif [ "${DEVICE}" == "Amlogic-ng" ] || [ "${DEVICE}" == "Amlogic-no" ] || ["${DEVICE}" == "Amlogic-ogu" ]; then
	PKG_MAKE_OPTS_TARGET=" platform=emuelec-ng"
else
	PKG_MAKE_OPTS_TARGET=" platform=emuelec-hh"
fi	
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp dosbox_pure_libretro.so ${INSTALL}/usr/lib/libretro/dosbox_pure_libretro.so
  cp dosbox_pure_libretro.info ${INSTALL}/usr/lib/libretro/dosbox_pure_libretro.info
  
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 dosbox_pure_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/dosbox_pure_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/dosbox_pure_libretro.so || { echo "预编译核心下载失败: dosbox_pure_libretro.so"; exit 1; }
}
