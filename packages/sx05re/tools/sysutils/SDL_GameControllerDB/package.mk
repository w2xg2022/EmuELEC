# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)

PKG_NAME="SDL_GameControllerDB"
PKG_VERSION="cead9cccf79c0865cf8c2b7b652867372d63cd6e"
PKG_SHA256="af45411e7b4a24b91f267cf2281c63df209e7552f41f29d9a4261a50363811e5"
PKG_LICENSE="OSS"
PKG_SITE="https://github.com/gabomdq/SDL_GameControllerDB"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A community sourced database of game controller mappings to be used with SDL2 Game Controller functionality"
PKG_TOOLCHAIN="manual"

pre_configure_target() {
# These maps are old, we use our own
sed -i "s/19000000010000000100000001010000,odroid/# 19000000010000000100000001010000,odroid/g" gamecontrollerdb.txt
sed -i "s/19000000010000000200000011000000,odroid/# 19000000010000000200000011000000,odroid/g" gamecontrollerdb.txt
sed -i "s/03000000d11800000094000011010000,Stadia Controller/# 03000000d11800000094000011010000,Stadia Controller/g" gamecontrollerdb.txt
sed -i "s/030000004c0500006802000011810000,PS3 Controller/# 030000004c0500006802000011810000,PS3 Controller/g" gamecontrollerdb.txt
sed -i "s/030005ff6d0400001dc2000014400000,Logitech Gamepad F310/# 030005ff6d0400001dc2000014400000,Logitech Gamepad F310/g" gamecontrollerdb.txt

# NOTE(w2xg2022): Xbox 360 家族(VID/PID 045E:028E)把 guide 对到 b8 —— 真 Xbox 手柄
# 中央那颗键。但市面上约七成「Xbox 式」山寨手柄【根本没有 Guide 键】,而 gptokeyb 的
# 退出组合是【guide + START】(硬编,不受 -hotkey 参数影响,已实测确认),于是这些手柄
# 在终端机/档案管理员/各独立模拟器里【永远退不出去】,只能靠跑一次设定精灵绕过
# (精灵会经 configscripts/gamecontrollerdb.sh 把 hotkeyenable 翻译成 guide 覆写此表)。
# 改成 b6(SELECT)后开箱即可 SELECT+START 退出,与画面上到处写的提示一致。
# ★E900V22C 实机验证★:用 SDL_GAMECONTROLLERCONFIG 覆盖同一笔为 guide:b6 后,
# 未跑精灵的全新固件即可 SELECT+START 退出 Launch Terminal。
# 代价:真 Xbox 手柄的 Guide 键不再是 SDL 的 guide;但真假手柄同 VID/PID、软件分不出来,
# 且七成没有该键,取多数。
sed -i "s/^\(030000005e0400008e02000010010000,.*\)guide:b8,/\1guide:b6,/" gamecontrollerdb.txt
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/config/SDL-GameControllerDB
  cp ${PKG_BUILD}/gamecontrollerdb.txt ${INSTALL}/usr/config/SDL-GameControllerDB
}
