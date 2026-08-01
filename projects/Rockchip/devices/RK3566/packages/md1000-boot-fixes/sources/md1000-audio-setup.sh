#!/bin/sh
# MD1000/RK3566:开机把 HDMI 音频路由准备好。必须在 ES 起来【之前】跑完,
# 所以 unit 是 Type=oneshot + Before=emustation.service。
#
# 为什么需要这个:EmuELEC 的 emuelec_autostart.sh 里复制 asound.conf 的分支
# 只认 Amlogic / Amlogic-ng / Amlogic-no,RK3566 一个都不符合,所以这台机器
# 【从来没有 ALSA 设定档】,预设装置就落在 card 0(可能是类比卡)=没声音。

CONF=/storage/.config/emuelec/configs/emuelec.conf
ASOUND=/storage/.config/asound.conf

mkdir -p /storage/.config

# --- 1. ee_audio_device:按卡名,不要用会漂移的卡号 -------------------
# 只在「没设过 / auto / 旧的数字写法」时才动它,使用者自己选过的值不覆盖。
CUR=""
[ -f "$CONF" ] && CUR=$(sed -n "s/^ee_audio_device=//p" "$CONF" | head -1)
case "$CUR" in
  ""|auto|[0-9]*)
    if [ -f "$CONF" ] && grep -q "^ee_audio_device=" "$CONF"; then
      sed -i "s|^ee_audio_device=.*|ee_audio_device=CARD=HDMI,DEV=0|" "$CONF"
    else
      mkdir -p "$(dirname "$CONF")"
      echo "ee_audio_device=CARD=HDMI,DEV=0" >> "$CONF"
    fi
    ;;
esac

# --- 2. asound.conf:没有才建立,不覆盖使用者改过的 -------------------
[ -f "$ASOUND" ] || cp /usr/share/md1000/asound.conf "$ASOUND"

# --- 3. ★接上 ALSA 真正会读的路径★ ---------------------------------
# EmuELEC 的工具都写 /storage/.config/asound.conf,但 ALSA 只看
# /etc/asound.conf 与 $HOME/.asoundrc(HOME=/storage)。/etc 是唯读的,
# 所以用软链把两边接起来,否则上面那份设定根本没人读。
ln -sf /storage/.config/asound.conf /storage/.asoundrc

exit 0
