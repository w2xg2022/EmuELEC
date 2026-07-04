# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="libmodplug"
PKG_VERSION="a35e253001b1bc9046b7955d0871f841f88f993b"
PKG_SHA256="ca51a07b9f6a5f9485c4ab8eb84c96e84a6cea8d3af4f9ba38f8150b8689af5e"
PKG_ARCH="any"
PKG_LICENSE="public domain"
PKG_SITE="https://gitlab.com/solarus-games/libmodplug"
# NOTE(w2xg2022): GitLab那個repo現在需要登入才能存取(git clone/瀏覽器都被擋，
# 多次實測確認)。這個套件是SDL2_mixer和solarus的必要依賴，掛掉會拖累一大片
# 後面的套件。把內容(跟GitLab上要的commit內容一致，已驗證)打包鏡像進repo。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/sx05re/tools/sound/modplug/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SHORTDESC="Modplug Plugin for XMMS v2.0 / libmodplug v0.8.5"
