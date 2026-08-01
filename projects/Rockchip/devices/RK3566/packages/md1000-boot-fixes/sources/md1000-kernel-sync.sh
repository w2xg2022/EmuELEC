#!/bin/sh
# ★刷了新固件却还在跑旧内核 —— 这个坑必须自愈★
#
# MD1000 是链载启动:u-boot 从 【eMMC】 的 /boot/emuelec/ 读 KERNEL 与 dtb,
# rootfs(SYSTEM)才在 U 盘上。而 initramfs 是【包在 KERNEL 里面的】。
# 所以把新映像刷到 U 盘,只换掉了 userland ——
#   eMMC 上的 KERNEL 还是旧的 => 内核层的修改、initramfs 的修改全都没生效,
#   但 /etc/os-release 却显示新版本,看起来一切正常,极容易误判。
#
# 以前每次都得从 Armbian 跑 switch-to-emuelec.sh 才进得来,同步顺便就做了;
# 自从 TRIGGER 改成常驻(正式固件不再一次性),直接重开就进 EmuELEC,
# 那一步被跳过了 —— 这是移除 TRIGGER 自动清除的副作用。
#
# 判定用 md5 而不是时间戳:时间戳会因为 FAT 分区、时区、复制方式而失真。
# 同 rocknix/docs/md1000-dual-boot.md 那份配方的教训。
#
# 注意:同步完要【下次开机】才生效,本次跑的仍是旧内核。

LOG=/emuelec/logs/kernel-sync.log
M=/tmp/md1000-emmc-sync

log() { echo "$(date '+%F %T') $*" >> "$LOG" 2>/dev/null; }

[ -f /flash/KERNEL ] || exit 0

mkdir -p "$M" || exit 0
mount /dev/mmcblk0p1 "$M" 2>/dev/null || { rmdir "$M" 2>/dev/null; exit 0; }

if [ -d "$M/emuelec" ]; then
  NEW=$(md5sum /flash/KERNEL 2>/dev/null | cut -d' ' -f1)
  OLD=$(md5sum "$M/emuelec/KERNEL" 2>/dev/null | cut -d' ' -f1)

  if [ -n "$NEW" ] && [ "$NEW" != "$OLD" ]; then
    log "KERNEL differs (emmc=${OLD:-none} usb=$NEW) - syncing"
    cp /flash/KERNEL "$M/emuelec/KERNEL" && log "KERNEL synced (takes effect next boot)"
  fi

  # dtb 一并同步(同样只有 eMMC 那份会被 u-boot 读到)
  for D in /flash/*.dtb; do
    [ -f "$D" ] || continue
    B=$(basename "$D")
    if [ "$(md5sum "$D" | cut -d' ' -f1)" != "$(md5sum "$M/emuelec/$B" 2>/dev/null | cut -d' ' -f1)" ]; then
      cp "$D" "$M/emuelec/$B" && log "$B synced"
    fi
  done

  sync
fi

umount "$M" 2>/dev/null
rmdir "$M" 2>/dev/null
exit 0
