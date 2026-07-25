# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="kmscon"
PKG_VERSION="0b3452719992f855b64fa21c9d7fbd6158a8d23a"
PKG_SHA256="6b7efdb4f9b6715208898ee4757364c04d1bb903182bba1667644dd68c11524d"
PKG_LICENSE="GPLv2+"
PKG_SITE="https://github.com/dvdhrm/kmscon"
PKG_URL="$PKG_SITE/archive/$PKG_VERSION.tar.gz"
# xkeyboard-config 提供 /usr/share/X11/xkb 键盘定义资料。libxkbcommon 找不到
# 它的话 kmscon 会在 "cannot create XKB context" 之后直接退出("no running
# seats"),整个终端机根本起不来 —— 实机实测踩到过,不是可有可无的相依。
# pango(含 pangoft2)提供可缩放的向量字型后端。没有它 kmscon 只能退回内建
# 8x16 点阵字,--font-size 形同无效,接在电视上字小到难读。字型档本身走
# fontconfig 找 "monospace",镜像里已有 LiberationMono。
PKG_DEPENDS_TARGET="toolchain libtsm libxkbcommon libdrm xkeyboard-config pango"
PKG_LONGDESC="Linux KMS/DRM based virtual Console Emulator"
PKG_TOOLCHAIN="autotools"


# drm2d (DRM dumb-buffer, software 2D) is enough for a text console and does a
# real KMS modeset, so it displays on DRM/KMS devices (e.g. Amlogic S905L3A /
# E900V22C) where the legacy fbdev console (fbterm) is never scanned out.
# drm3d is dropped on purpose: it needs libgbm/Mesa GL which a terminal doesn't.
#
# --with-fonts 明确写出来是有意的:pango 后端预设是「找不到 libpango 就静默
# 降级成点阵字」,之前就是这样悄悄出了一版字小到难读的终端机。明确指定后
# 缺相依会直接 AC_ERROR 中断编译,坏掉会当场看见,而不是等到实机才发现。
PKG_CONFIGURE_OPTS_TARGET=" --disable-debug --with-video=fbdev,drm2d --disable-multi-seat --with-sessions=dummy,terminal --with-fonts=unifont,pango"
