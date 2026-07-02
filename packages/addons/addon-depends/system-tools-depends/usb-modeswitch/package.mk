# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="usb-modeswitch"
PKG_VERSION="2.6.1"
PKG_SHA256="5195d9e136e52f658f19e9f93e4f982b1b67bffac197d0a455cd8c2cd245fa34"
PKG_LICENSE="GPL"
PKG_SITE="http://www.draisberghof.de/usb_modeswitch/"
# NOTE(w2xg2022): draisberghof.de對雲端runner IP回403，其餘官方鏡像(sources.
# coreelec.org/sources.libreelec.tv)都404，跟dialog/wsdd2同一種問題。改用
# repo內自帶鏡像(源碼取自VM本地sources/快取，sha256跟package.mk記錄的完全
# 一致，驗證為正版原始檔案)。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/addons/addon-depends/system-tools-depends/usb-modeswitch/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain libusb"
PKG_LONGDESC="USB_ModeSwitch - Handling Mode-Switching USB Devices on Linux"
PKG_BUILD_FLAGS="-sysroot"

makeinstall_target() {
	mkdir -p $INSTALL/usr/sbin
	cp usb_modeswitch $INSTALL/usr/sbin
}
