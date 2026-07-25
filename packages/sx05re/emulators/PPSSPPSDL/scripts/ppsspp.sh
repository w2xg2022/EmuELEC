#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

. /etc/profile

ROMSPPSSPPFOLDER=/storage/roms/savestates/PPSSPPSDL/PSP
PPSSPPFOLDER=/storage/.config/ppsspp/PSP/
AUTOGP=$(get_ee_setting ppssppsdl_auto_gamepad)
CHEEVOS=$(get_ee_setting global.retroachievements)


if [[ "${AUTOGP}" == "1" ]]; then
	set_ppsspp_joy.sh
fi

if [[ "${CHEEVOS}" == "1" ]]; then
	ppssppcheevos.sh
fi

# NOTE(w2xg2022): 强制PPSSPP独立模拟器UI语言跟随ES/system.language,比照setsettings.sh
# 对RetroArch的做法(读system.language→写进配置)。PPSSPP的语言码就是assets/lang/*.ini
# 的文件名(zh_CN/zh_TW/ja_JP...),与system.language基本一致,只需处理几个别名;并用「翻译
# 档存在」把关,映射不到就保留原值不乱设。每次启动都同步=ES设什么语言,PSP独立模拟器就跟着走。
EE_LANG=$(get_ee_setting system.language)
case "${EE_LANG}" in
	cs_CZ)       PPLANG="cz_CZ" ;;   # PPSSPP捷克语文件名是cz_CZ
	en_GB)       PPLANG="en_US" ;;
	es_MX|eu_ES) PPLANG="es_ES" ;;
	*)           PPLANG="${EE_LANG}" ;;
esac
PPINI="/storage/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
if [ -n "${PPLANG}" ] && [ -f "/storage/.config/ppsspp/assets/lang/${PPLANG}.ini" ] && [ -f "${PPINI}" ]; then
	# 只改[General]里UI语言那行(值以字母开头),避开另一行数字的 Language = N(模拟PSP主机语言)
	sed -i "s/^Language = [a-zA-Z].*/Language = ${PPLANG}/" "${PPINI}"
fi

# Make sure we have the correct symlinks
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
    mkdir -p "${ROMSPPSSPPFOLDER}"
    
   if [ ! -L /storage/.config/ppsspp/PSP/${dir} ]; then
		cp -rf /storage/.config/ppsspp/PSP/${dir}/. ${ROMSPPSSPPFOLDER}/${dir}/
		rm -rf /storage/.config/ppsspp/PSP/${dir}
		ln -sf ${ROMSPPSSPPFOLDER}/${dir} /storage/.config/ppsspp/PSP/${dir}
    fi
done

if [ ! -s "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" ];then 
	mkdir -p "${ROMSPPSSPPFOLDER}/Cheats/"
	cp -rf /usr/config/ppsspp/PSP/SYSTEM/Cheats/. "${ROMSPPSSPPFOLDER}/Cheats/" 

	CHEAT_DB_VERSION="06d4d6148b66109005f7d51c37e8344f0bc042cc"
	curl -sLo "${ROMSPPSSPPFOLDER}/Cheats/cheat.db" -f "https://raw.githubusercontent.com/Saramagrean/CWCheat-Database-Plus-/${CHEAT_DB_VERSION}/cheat.db" || true
fi

ARG=${1//[\\]/}
export SDL_AUDIODRIVER=alsa          
PPSSPPSDL --fullscreen "${ARG}"
