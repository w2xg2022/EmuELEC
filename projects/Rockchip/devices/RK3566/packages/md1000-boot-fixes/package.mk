# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 w2xg2022

# MD1000 / RK3566 的板级开机修正,烤进固件而不是留在 /storage:
#
#   1. HDMI 音频路由(md1000-audio-setup.sh)
#      这台机器从来没有 ALSA 设定档 —— emuelec_autostart.sh 里复制 asound.conf
#      的分支只认 Amlogic 系,RK3566 不符合。缺档就预设落到 card 0 = 没声音。
#      要在 ES 起来之前做完,所以是 oneshot + Before=emustation.service。
#
#   2. 同步链载内核(md1000-kernel-sync.sh)
#      ★刷了新固件却还在跑旧内核的坑★:u-boot 从 eMMC 读 KERNEL(initramfs 包在里面),
#      rootfs 才在 U 盘。刷 U 盘只换 userland,eMMC 的 KERNEL 还是旧的,但
#      /etc/os-release 显示新版本 —— 看起来一切正常,极易误判。
#      以前靠 switch-to-emuelec.sh 顺便同步;TRIGGER 改常驻后那步被跳过了。
#
#   3. 重新 probe 蓝牙的 serdev(md1000-bt-fix.sh)
#      RTL8822CS 的 hci0 内核侧正常但 bluetoothd 不认,需要重新 probe。
#      要长期活着做轮询重试,所以是 Type=simple + KillMode=process。
#
# ★不再清 /boot/emuelec/TRIGGER★
# 早期版本会在开机时删掉链载 flag,让 EmuELEC 变成「一次性」(卡住就断电回
# Armbian)。那是开发期的安全网,正式固件不烤进去 —— 否则每次重开都掉回
# Armbian。TRIGGER 改由 switch-to-emuelec.sh / switch-to-armbian.sh 明确管理。
#
# 之所以做成独立 package 而不是塞进 custom_start.sh:后者是
# packages/sx05re/emuelec/config/ 的共用文件(动它会波及 X98mini/E900V22C 等
# 所有机型),而且语义上属于"使用者的文件"——使用者一编辑,板级修正就没了。

PKG_NAME="md1000-boot-fixes"
PKG_VERSION=""
PKG_SHA256=""
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE=""
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain systemd"
PKG_LONGDESC="MD1000/RK3566 board-level boot fixes (HDMI audio routing, RTL8822CS BT re-probe)"
PKG_TOOLCHAIN="manual"

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_DIR}/sources/md1000-audio-setup.sh ${INSTALL}/usr/bin/
  cp ${PKG_DIR}/sources/md1000-bt-fix.sh      ${INSTALL}/usr/bin/
  cp ${PKG_DIR}/sources/md1000-kernel-sync.sh ${INSTALL}/usr/bin/
  chmod 755 ${INSTALL}/usr/bin/md1000-audio-setup.sh
  chmod 755 ${INSTALL}/usr/bin/md1000-bt-fix.sh
  chmod 755 ${INSTALL}/usr/bin/md1000-kernel-sync.sh

  mkdir -p ${INSTALL}/usr/share/md1000
  cp ${PKG_DIR}/sources/asound.conf ${INSTALL}/usr/share/md1000/
}

post_install() {
  enable_service md1000-audio-setup.service
  enable_service md1000-bt-fix.service
  enable_service md1000-kernel-sync.service
}
