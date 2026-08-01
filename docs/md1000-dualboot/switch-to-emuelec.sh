#!/bin/sh
# Armbian -> 进 USB EmuELEC（一键：需要时自动完成一次性安装，然后 booti 链载）
#
# 原理：eMMC /boot/boot.cmd 开机见到 /boot/emuelec/TRIGGER 就 booti eMMC 的
#       emuelec/KERNEL 链载 EmuELEC（rootfs 从 U 盘 LABEL=EMUELEC / STORAGE）。
#       首次运行本脚本会自动：
#       ① 把 U 盘 EmuELEC 的 KERNEL + rk3566-md1000.dtb 铺到 eMMC /boot/emuelec/
#       ② 往 /boot/boot.cmd 插入链载判断块、重编 boot.scr（自动备份 *.armbian-orig）
# 安全：没 TRIGGER 时 Armbian 照常开机；链载失败（如拔了 U 盘）也落回 Armbian，绝不变砖。
set -e
BASE=https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/md1000-dualboot
[ "$(id -u)" = "0" ] || { echo "请用 root 运行"; exit 1; }

# ① 每次都把 U 盘上的 KERNEL + dtb 同步到 eMMC
#
# ★刷了新固件却还在跑旧内核，是这套链载最容易踩的坑★：u-boot 读的是 eMMC 的
# /boot/emuelec/{KERNEL,rk3566-md1000.dtb}，而刷新固件只换掉 U 盘上的那一份。
# 两者没有任何东西会自动配对 —— 于是 /etc/os-release 显示新版本、实际跑的却是
# 旧内核（initramfs 也包在 KERNEL 里，所以内核层与 initramfs 的修改全部没生效）。
# 判定用 md5 而不是时间戳：时间戳会因为 FAT 分区、时区、复制方式而失真。
#
# 注：EmuELEC 固件里另有 md1000-kernel-sync.service，进过一次 EmuELEC 之后
#     它每次开机都会自己做同样的同步（见 packages/md1000-boot-fixes/）。
#     所以这里主要是给「首次安装」和「从 Armbian 侧刷完新 U 盘」用的。
#
# 找不到 U 盘时：已有副本就只警告不中断（不比旧行为差），没副本才是真的没法继续。
sync_payload() {
  UMNT=""

  # 优先按标签找（EmuELEC 的 boot 分区 DISTRO_BOOTLABEL="EMUELEC"）
  P=$(blkid -L EMUELEC 2>/dev/null || true)
  if [ -n "$P" ]; then
    m=$(mktemp -d)
    if mount -o ro "$P" "$m" 2>/dev/null && [ -f "$m/KERNEL" ]; then
      USB="$P"; UMNT="$m"
    else
      umount "$m" 2>/dev/null || true; rmdir "$m" 2>/dev/null || true
    fi
  fi

  # 退回扫描（标签被改过、或多张卡时）
  if [ -z "$UMNT" ]; then
    for p in $(ls /dev/sd?1 2>/dev/null); do
      m=$(mktemp -d)
      if mount -o ro "$p" "$m" 2>/dev/null && [ -f "$m/KERNEL" ]; then USB="$p"; UMNT="$m"; break; fi
      umount "$m" 2>/dev/null || true; rmdir "$m" 2>/dev/null || true
    done
  fi

  if [ -z "$UMNT" ]; then
    if [ -f /boot/emuelec/KERNEL ] && [ -f /boot/emuelec/rk3566-md1000.dtb ]; then
      echo "!! 找不到 U 盘 EmuELEC 分区，沿用 eMMC 上现有的 KERNEL/dtb"
      echo "!! 若刚刷过新固件，这次链载跑的会是旧内核/旧 dtb —— 插好 U 盘再跑一次本脚本"
      return 0
    fi
    echo "找不到带 KERNEL 的 U 盘 EmuELEC 分区（插好 U 盘再跑）"; exit 1
  fi
  echo "U 盘 EmuELEC 分区 = $USB"

  # ★与 ROCKNIX 的差别★：ROCKNIX 的 dtb 在 device_trees/ 子目录，
  # EmuELEC 的 mkimage 是 `mcopy -o "$dtb" ::`，dtb 落在 boot 分区【根目录】。
  DTB="$UMNT/rk3566-md1000.dtb"
  [ -f "$DTB" ] || DTB="$(ls "$UMNT"/*.dtb 2>/dev/null | head -1)"
  [ -f "$DTB" ] || { echo "U 盘里缺 *.dtb"; umount "$UMNT"; rmdir "$UMNT" 2>/dev/null || true; exit 1; }

  mkdir -p /boot/emuelec
  changed=0
  for pair in "$UMNT/KERNEL:/boot/emuelec/KERNEL" "$DTB:/boot/emuelec/rk3566-md1000.dtb"; do
    src=${pair%:*}; dst=${pair#*:}
    if [ ! -f "$dst" ] || [ "$(md5sum <"$src" | cut -d' ' -f1)" != "$(md5sum <"$dst" | cut -d' ' -f1)" ]; then
      cp -f "$src" "$dst"; changed=1
      echo "  已更新 $(basename "$dst")"
    fi
  done
  sync; umount "$UMNT"; rmdir "$UMNT" 2>/dev/null || true
  [ "$changed" = "1" ] || echo "  KERNEL/dtb 与 U 盘一致，无需更新"
}

echo "== 同步链载用的 KERNEL/dtb =="
sync_payload

# 判断是否还需要装 boot.cmd 链载块（这一步才是真的只做一次）
if ! grep -q 'emuelec/TRIGGER' /boot/boot.cmd 2>/dev/null; then
  echo "== 首次：安装 boot.cmd 链载块 =="
  command -v mkimage >/dev/null 2>&1 || { echo "缺 mkimage —— 先装：apt-get update && apt-get install -y u-boot-tools"; exit 1; }

  # ② 装 boot.cmd 链载块 + 重编 boot.scr（带备份）
  [ -f /boot/boot.cmd.armbian-orig ] || cp /boot/boot.cmd /boot/boot.cmd.armbian-orig
  [ -f /boot/boot.scr.armbian-orig ] || cp /boot/boot.scr /boot/boot.scr.armbian-orig
  if [ -f "$(dirname "$0")/boot-emuelec-block.txt" ]; then
    cp "$(dirname "$0")/boot-emuelec-block.txt" /tmp/ee-blk.txt
  else
    curl -fsSL "$BASE/boot-emuelec-block.txt" -o /tmp/ee-blk.txt
  fi
  # 在第一处 'setenv load_addr' 之前插入链载块
  awk 'FNR==NR{blk=blk $0 ORS; next} /setenv load_addr/ && !d{printf "%s", blk; d=1} {print}' \
      /tmp/ee-blk.txt /boot/boot.cmd > /boot/boot.cmd.new
  if ! grep -q 'emuelec/TRIGGER' /boot/boot.cmd.new; then
    echo "插入失败（找不到 'setenv load_addr' 锚点），boot.cmd 未改动，已中止"; rm -f /boot/boot.cmd.new; exit 1
  fi
  mv /boot/boot.cmd.new /boot/boot.cmd
  mkimage -C none -A arm -T script -n 'flatmax load script' -d /boot/boot.cmd /boot/boot.scr >/dev/null
  echo "已装链载块并重编 boot.scr（备份：/boot/boot.{cmd,scr}.armbian-orig）"
fi

# 切换：放 TRIGGER，下次开机 -> EmuELEC
touch /boot/emuelec/TRIGGER
sync
echo "已放 TRIGGER，下次开机 -> EmuELEC (USB)。3 秒后重启..."
sleep 3
reboot
