#!/bin/sh
# MD1000:RTL8822CS 的 hci0 在内核这边起得好好的、固件也载入了,但 bluetoothd
# 的 mgmt 接口就是不认它(bluetoothctl 一直报 "No default controller available")。
# 单纯 restart bluetooth 没用,必须把 serdev 重新 probe 一次,让适配器在
# bluetoothd 已经在跑的时候重新注册。
#
# ★用轮询重试,不要用固定延迟★:EmuELEC 的 emuelec_autostart.sh 后面还会跑
# 60 秒的蓝牙手把扫描,固定 sleep 到点动手会被它盖掉。时机不能用猜的,
# 改成「检查 → 没成功才修 → 再检查」。
#
# ★本脚本是 Type=simple 的主进程,不要 setsid 丢背景★
# 旧版是 Type=oneshot + setsid:oneshot 预设 KillMode=control-group,主进程
# 一结束就把同 cgroup 里剩下的进程全杀掉;setsid 只脱离 session,【没有脱离
# cgroup】,所以那个重试回圈一启动就被杀了 —— 实机验证过,确实没生效。

log() { echo "[md1000-bt] $*"; }

i=0
while [ $i -lt 20 ]; do
  sleep 15
  i=$((i + 1))

  if printf "show\n" | timeout 8 bluetoothctl 2>/dev/null | grep -q "Controller "; then
    log "controller present (try $i) - done"
    exit 0
  fi

  log "no controller (try $i) - re-probing serdev"
  killall bluetoothctl 2>/dev/null
  echo serial0-0 > /sys/bus/serial/drivers/hci_uart_h5/unbind 2>/dev/null
  sleep 2
  echo serial0-0 > /sys/bus/serial/drivers/hci_uart_h5/bind 2>/dev/null
  sleep 6
  systemctl --no-block restart bluetooth
done

log "giving up after $i tries"
exit 0
