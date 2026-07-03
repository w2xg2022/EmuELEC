# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="mupen64plus-nx-alt"
PKG_VERSION="680e033fc8ed1a49df7b156d97164e0050ee13bc"
PKG_SHA256="ffadc0144406df9875e1cb5e788d619fcddc6c7d5df61692be8c67c86d5b8fcb"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/libretro/mupen64plus-libretro-nx"
# NOTE(w2xg2022): 上游repo在mupen64plus-rsp-paraLLEl/lightning/gnulib這個路徑
# 有一個子模組(submodule)標記，卻沒在頂層.gitmodules登記對應網址(上游repo本身
# 設定壞掉，跟連線無關，實測git submodule update --init --recursive在這個
# commit必定失敗)。改用GitHub自動產生的archive壓縮檔下載(不會觸發有問題的
# 遞迴子模組抓取，archive本身就不含子模組內容)，繞開這個壞掉的機制。
# gnulib子模組內容(commit e54b645fc6b8422562327443bda575c65d931fbd，取自
# https://github.com/coreutils/gnulib.git，已驗證是編譯需要的正確版本)改成
# 隨repo一起commit的gnulib-e54b645f.tar.gz(壓縮後7MB)，在pre_configure_target
# 手動解壓回正確路徑。
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain nasm:host ${OPENGLES}"
PKG_SECTION="libretro"
PKG_LONGDESC="Improved mupen64plus libretro core reimplementation"
PKG_TOOLCHAIN="make"
PKG_BUILD_FLAGS="-lto"
PKG_EE_UPDATE=no

pre_configure_target() {
  rm -rf mupen64plus-rsp-paraLLEl/lightning/gnulib
  mkdir -p mupen64plus-rsp-paraLLEl/lightning/gnulib
  tar xf "${PKG_DIR}/gnulib-e54b645f.tar.gz" -C mupen64plus-rsp-paraLLEl/lightning/gnulib

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
  cp mupen64plus_next_libretro.so ${INSTALL}/usr/lib/libretro/mupen64plus_next_alt_libretro.so
}
