# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mupen64plus-nx"
PKG_VERSION="222acbd3f98391458a047874d0372fe78e14fe94"
PKG_SHA256="9e55fa83f2313f9b80a369d77457ec216e5774ef2d486083ad8661aa94a4dbd1"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_SECTION="libretro"
PKG_SHORTDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_LONGDESC="mupen64plus + RSP-HLE + GLideN64 + libretro"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"

pre_configure_target() {
  sed -e "s|^GIT_VERSION ?.*$|GIT_VERSION := \" ${PKG_VERSION:0:7}\"|" -i Makefile

PKG_MAKE_OPTS_TARGET+=" HAVE_PARALLEL_RDP=1 HAVE_PARALLEL_RSP=1 HAVE_THR_AL=1 LLE=1"

if [ ${ARCH} == "arm" ]; then
	if [ "${DEVICE}" = "Amlogic-old" ]; then
		PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=OLD32BIT"
	elif [ "${DEVICE}" = "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
		sed -i "s|cortex-a53|cortex-a35|g" Makefile
		PKG_MAKE_OPTS_TARGET+=" platform=odroidgoa"
	elif [ "${DEVICE}" == "OdroidM1" ] || [ "${DEVICE}" == "RK356x" ]; then
		PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=NGRK32BIT"
	else
		PKG_MAKE_OPTS_TARGET+=" platform=AMLG12B"
	fi
else
	if [ "${DEVICE}" = "Amlogic-old" ]; then 
		PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=OLD"
	elif [ "${DEVICE}" == "OdroidM1" ] || [ "${DEVICE}" == "RK356x" ]; then
		PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=NGRK"
	elif [ "${DEVICE}" = "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
		PKG_MAKE_OPTS_TARGET+=" platform=emuelec BOARD=NGHH"
	else
		PKG_MAKE_OPTS_TARGET+=" platform=odroid64 BOARD=N2"
	fi
fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 mupen64plus_next_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/mupen64plus_next_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/mupen64plus_next_libretro.so || { echo "预编译核心下载失败: mupen64plus_next_libretro.so"; exit 1; }
}
