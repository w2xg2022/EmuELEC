# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="dialog"
PKG_VERSION="1.3-20220117"
PKG_SHA256="754cb6bf7dc6a9ac5c1f80c13caa4d976e30a5a6e8b46f17b3bb9b080c31041f"
PKG_LICENSE="GNU-2.1"
PKG_SITE="https://invisible-mirror.net/archives/dialog"
# NOTE(w2xg2022): invisible-mirror.net(Sucuri WAF)疑似封鎖GitHub Actions雲端
# runner的IP(同樣請求用一般UA直接測試正常，但雲編譯連續多次415/404)，改用
# 自家repo內鏡像的原始檔案，避免雲編譯卡在這個小檔案下載上。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/sx05re/tools/sysutils/dialog/dialog-${PKG_VERSION}.tgz"
PKG_DEPENDS_TARGET="toolchain ncurses"
PKG_LONGDESC="This version of dialog, formerly known as cdialog is based on the Debian package for dialog 0.9a"
PKG_TOOLCHAIN="auto"

PKG_CONFIGURE_OPTS_TARGET="--with-ncurses --disable-rpath-hack"


