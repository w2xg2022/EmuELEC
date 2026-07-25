#!/usr/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

EE_DEVICE=$(cat /ee_arch)

# 终端机后端选择
#
# fbterm 只会往 legacy fbdev(/dev/fb0)写像素,它不做 KMS modeset,也不参与
# DRM 的合成。在 EmulationStation 走 SDL kmsdrm 的机器上(例如 Amlogic
# S905L3A / E900V22C),ES 一旦当过 DRM master,fbdev 那块缓冲就不再是真正被
# 扫描输出的画面 —— fbterm 照样在跑、内容也确实写进了 /dev/fb0,但屏幕全黑。
#
# kmscon 则是 DRM/KMS 原生终端:自己开 VT、自己做 modeset、把自己的 buffer
# 挂上输出平面(实机验证:切过去之后扫描输出平面的 fb 从 "allocated by
# [fbcon]" 变成 "allocated by = kmscon",画面正常显示)。
#
# 所以只要镜像里带了 kmscon 就优先用它,没有才退回 fbterm。
if [ -x /usr/bin/kmscon ]; then
    EE_TERM="kmscon"
else
    EE_TERM="fbterm"
fi

# kmscon 会切到自己的 VT,退出后要切回原本那个,免得回到 ES 时停在别的 VT 上。
# 用 trap 而不是在 kmscon 后面接一行:退出终端机是靠 gptokeyb 送 SIGTERM,
# 那一刀有机会连这支脚本一起带走,写在后面的指令就永远跑不到了。
EE_PREV_VT="$(cat /sys/class/tty/tty0/active 2>/dev/null)"
EE_PREV_VT="${EE_PREV_VT#tty}"

ee_restore_vt() {
    [ -n "${EE_PREV_VT}" ] && chvt "${EE_PREV_VT}" 2>/dev/null
}

# 掌机屏幕小,沿用原本 OGA/GameForce 的 8 号字;电视机型对齐 fbterm 的 -s 24。
if [ "${EE_DEVICE}" == "OdroidGoAdvance" ] || [ "${EE_DEVICE}" == "GameForce" ]; then
    EE_TERM_FONTSIZE=8
else
    EE_TERM_FONTSIZE=24
fi

run_kmscon() {
    trap ee_restore_vt EXIT TERM INT
    kmscon --font-size "${EE_TERM_FONTSIZE}" --login -- "${@}"
    ee_restore_vt
    trap - EXIT TERM INT
}

ee_console enable

if [[ "${1}" == *"launch_terminal_(kb).sh"* ]]; then
        ee_console disable
    if [ "${EE_TERM}" == "kmscon" ]; then
        run_kmscon /usr/bin/login -p -f root
    else
		tmpsh=/tmp/tmp.$$.sh
		echo "/usr/bin/login -p -f root" > ${tmpsh}
		chmod +x ${tmpsh}
		fbterm "${tmpsh}" -s 24 < /dev/tty1
		rm ${tmpsh}
    fi
elif [[ "${1}" == *"file_manager.sh"* ]]; then
        if [ "${EE_TERM}" == "kmscon" ]; then
            run_kmscon /bin/bash "${1}"
        else
            fbterm "${1}" -s 24 < /dev/tty1
        fi
else
		case ${1} in
		"mplayer_video")
            bash playvideo.sh "${2}" "${3}" < /dev/tty0
		;;
		*)
            bash "${1}" > /dev/tty0
        ;;
		esac
fi

ee_console disable
