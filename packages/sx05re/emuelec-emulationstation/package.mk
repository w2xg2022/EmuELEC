# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

# es4all: 源码改由统一仓库 es4all 提供（原 EmuELEC/emuelec-emulationstation）。
# NOTE(w2xg2022): 2026-07-23 es4all 1.1 定版, 分支 v1.1-dev 已【改名】为 v1.1-stable
# (远端 v1.1-dev 已不存在)。★分支栏没跟着改会直接 clone 失败★。
# 往后规则: 发版时从开发分支【复制】出 vX.Y-stable(不再改名, 免得别人釘的分支突然消失),
# 开发线走 vX.Y-dev。要编哪一版自己选釘 -stable(冻结)或 -dev(开发中)。
PKG_NAME="emuelec-emulationstation"
PKG_VERSION="495e5bf8ad2863af591f89a8c1cfa705c9fc37f2"
PKG_GIT_CLONE_BRANCH="v1.1-stable"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/w2xg2022/es4all"
PKG_URL="${PKG_SITE}.git"
PKG_DEPENDS_TARGET="toolchain SDL2 freetype freeimage vlc rapidjson ${OPENGLES} SDL2_mixer fping p7zip espeak"
PKG_SECTION="emuelec"
PKG_SHORTDESC="Emulationstation emulator frontend"
PKG_BUILD_FLAGS="-gold"
GET_HANDLER_SUPPORT="git"


if [[ ${DEVICE} == "OdroidGoAdvance"  ]] || [[ ${DEVICE} == "GameForce"  ]]; then
	PKG_PATCH_DIRS="Rockchip/HH"
fi

if [[ ${DEVICE} == "OdroidM1"  ]] || [[ ${DEVICE} == "RK356x"  ]]; then
	PKG_PATCH_DIRS="Rockchip"
fi

# themes for Emulationstation
# NOTE(w2xg2022): es-theme-alekfull-EmueELEC 才是实际生效的默认主题(见
# es_settings.cfg 的 ThemeSet)。Crystal(280MB 未压缩, 全 SYSTEM 最大的单一目录)
# 只是选单里可切换的备用主题, 从未被默认使用。EMMC_SLIM(默认yes)时不装它, 腾出
# 空间给 E900V22C 的 1GB system 分区(见 emuelec/package.mk 的 SLIM_EXCLUDE 同一
# 用户决定); 默认外观不受影响, 只是选单少一个可选主题。EMMC_SLIM=no 时装回。
if [ "${EMMC_SLIM:-yes}" != "no" ]; then
  PKG_DEPENDS_TARGET="${PKG_DEPENDS_TARGET} es-theme-alekfull-EmueELEC"
else
  PKG_DEPENDS_TARGET="${PKG_DEPENDS_TARGET} Crystal es-theme-alekfull-EmueELEC"
fi

pre_configure_target() {

# build directly in ${PKG_BUILD} to avoid Python3 errors
  cd ${PKG_BUILD}
  rm -rf .${TARGET_NAME}

# es4all: 原本在此对源码做的 build-time patch(下载.po/繁简/手柄标签/注入InvertGameButtons)
# 已全部内建进 es4all 源码，故移除，避免重复插入导致选单出现两个相同开关。


# ★2026-07-21★ 这里★不要★再传 -DES4ALL_BUILD_SHA。
# 历史: 2026-07-20 曾加上它, 用来解「1.1pre 永远显示有更新可用」的假警报 —— 当时的
# 自我更新机制是拿「编进 binary 的 commit SHA」当构建指纹, 我们没传就是空字串,
# 空字串永远 != 官方 release 的 SHA, 于是永远提示有更新。
# 现况: es4all 已把该机制整个改掉(见 [[es4all_self_update]] 与 es4all 的
# CMakeLists.txt:105「不要再把 commit SHA 编进 binary」)。新指纹 = 整包内容的
# 确定性 md5(binary+resources+locale), CI 产生 <zip>.md5, 装置在 OTA 安装时把值
# 记进旁档 es4all-installed.md5。为此上游已移除 __DATE__/__TIME__ 与
# -DES4ALL_BUILD_SHA —— 因为新机制的前提是★相同源码必须编出相同 binary★。
# 所以再传这个参数不只无效, 还会把 commit SHA 编回 binary、让每次建置的 md5 都不同,
# 反而破坏新机制、令假警报以另一种形式复活。
PKG_CMAKE_OPTS_TARGET=" -DES4ALL_TARGET=emuelec -DENABLE_EMUELEC=1 -DDISABLE_KODI=1 -DENABLE_FILEMANAGER=1 -DGLES2=1 -DENABLE_TTS=1"

# Read api_keys.txt if it exist to add the required keys for cheevos, thegamesdb and screenscrapper. You need to get your own API keys.
# File should be in this format
# -DSCREENSCRAPER_DEV_LOGIN=devid=<devusername>&devpassword=<devpassword>
# -DGAMESDB_APIKEY=<gamesdbapikey>
# -DCHEEVOS_DEV_LOGIN=z=<yourusername>&y=<yourapikey>
# and it should be placed next to this file

if [ -f ${PKG_DIR}/api_keys.txt ]; then
while IFS="" read -r p || [ -n "${p}" ]
do
  PKG_CMAKE_OPTS_TARGET+=" ${p}"
done < ${PKG_DIR}/api_keys.txt
fi

if [[ ${DEVICE} == "GameForce" ]]; then
PKG_CMAKE_OPTS_TARGET+=" -DENABLE_GAMEFORCE=1"
fi

if [[ ${DEVICE} == "OdroidGoAdvance"  ]]; then
PKG_CMAKE_OPTS_TARGET+=" -DODROIDGOA=1"
fi

}

makeinstall_target() {

	mkdir -p ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps
	cp -rf ${PKG_BUILD}/locale/lang/* ${INSTALL}/usr/config/emuelec/configs/locale/
	cp -PR "$(get_build_dir glibc)/localedata/charmaps/UTF-8" ${INSTALL}/usr/config/emuelec/configs/locale/i18n/charmaps/UTF-8

	mkdir -p ${INSTALL}/usr/lib
	ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/lib/locale

	mkdir -p ${INSTALL}/usr/config/emulationstation/resources
    cp -rf ${PKG_BUILD}/resources/* ${INSTALL}/usr/config/emulationstation/resources/

    mkdir -p ${INSTALL}/usr/bin
    ln -sf /storage/.config/emulationstation/resources ${INSTALL}/usr/bin/resources
    cp -rf ${PKG_BUILD}/emulationstation ${INSTALL}/usr/bin
    cp -PR "$(get_build_dir glibc)/.${TARGET_NAME}/locale/localedef" ${INSTALL}/usr/bin

	mkdir -p ${INSTALL}/etc/emulationstation/
	ln -sf /storage/.config/emulationstation/themes ${INSTALL}/etc/emulationstation/

	mkdir -p ${INSTALL}/usr/config/emulationstation
	cp -rf ${PKG_DIR}/config/scripts ${INSTALL}/usr/config/emulationstation
	cp -rf ${PKG_DIR}/config/*.cfg ${INSTALL}/usr/config/emulationstation
	cp -rf ${PKG_DIR}/config/resources ${INSTALL}/usr/config/emulationstation/

	# Generate es_systems.cfg from json
	python3 ${PKG_DIR}/generate_es_systems.py -i ${PKG_DIR}/config/es_systems.json -o ${INSTALL}/usr/config/emulationstation/es_systems.cfg -b manufacturer

	chmod +x ${INSTALL}/usr/config/emulationstation/scripts/*
	chmod +x ${INSTALL}/usr/config/emulationstation/scripts/configscripts/*
	find ${INSTALL}/usr/config/emulationstation/scripts/ -type f -exec chmod o+x {} \;

	# Vertical Games are only supported in the OdroidGoAdvance
    if [[ ${DEVICE} != "OdroidGoAdvance" ]]; then
        sed -i "s|, vertical||g" "${INSTALL}/usr/config/emulationstation/es_features.cfg"
    fi

	# Amlogic project has an issue with mixed audio
    if [[ "${DEVICE}" == "Amlogic-old" ]]; then
        sed -i "s|</config>|	<bool name=\"StopMusicOnScreenSaver\" value=\"false\" />\n</config>|g" "${INSTALL}/usr/config/emulationstation/es_settings.cfg"
    fi

    if [[ "${DEVICE}" == "OdroidGoAdvance" ]] || [[ "${DEVICE}" == "GameForce" ]]; then
        sed -i "s|<\/config>|	<string name=\"GamelistViewStyle\" value=\"Small Screen\" />\n<\/config>|g" "${INSTALL}/usr/config/emulationstation/es_settings.cfg"
        sed -i "s|value=\"panel\" />|value=\"small panel\" />|g" "${INSTALL}/usr/config/emulationstation/es_settings.cfg"
    fi

    if  [[ "${DEVICE}" == "GameForce" ]]; then
    	mkdir -p ${INSTALL}/usr/config/emulationstation/themesettings
        sed -i "s|<\/config>|	<string name=\"subset.ratio\" value=\"43\" />\n<\/config>|g" "${INSTALL}/usr/config/emulationstation/es_settings.cfg"
        echo "subset.ratio=43" > ${INSTALL}/usr/config/emulationstation/themesettings/Crystal.cfg
    fi

# Remove unused cores
CORESFILE="${INSTALL}/usr/config/emulationstation/es_systems.cfg"

if [[ "${DEVICE}" != "Amlogic-ng" || "${DEVICE}" != "Amlogic-ne" || "${DEVICE}" != "Amlogic-no" ]]; then
    if [[ ${DEVICE} == "OdroidGoAdvance" || "${DEVICE}" == "GameForce" ]]; then
        remove_cores="mesen-s quicknes mame2016 mesen"
    elif [ "${DEVICE}" == "Amlogic-old" ]; then
        remove_cores="mesen-s quicknes mame2016 mesen yabasanshiroSA yabasanshiro"
        xmlstarlet ed -L -P -d "/systemList/system[name='saturn']" ${CORESFILE}
        xmlstarlet ed -L -P -d "/systemList/system[name='philips-cdi']" ${CORESFILE}
        xmlstarlet ed -L -P -d "/systemList/system/emulators/emulator[@name='Duckstation']" ${CORESFILE}
    fi

    for discore in ${remove_cores}; do
        sed -i "s|<core>${discore}</core>||g" ${CORESFILE}
        sed -i '/^[[:space:]]*$/d' ${CORESFILE}
    done
fi

# Remove Retrorun For unsupported devices
if [[ ${DEVICE} != "OdroidGoAdvance" ]] && [[ "${DEVICE}" != "GameForce" ]]; then
	xmlstarlet ed -L -P -d "/systemList/system/emulators/emulator[@name='retrorun']" ${CORESFILE}
else
	# remove duckstation for the OGA/GF
	xmlstarlet ed -L -P -d "/systemList/system/emulators/emulator[@name='Duckstation']" ${CORESFILE}

	# set parallel_n64_32b as default for handhelds
	sed -i "s|<core default=\"true\">mupen64plus_next</core>|<core>mupen64plus_next</core>|g" ${CORESFILE}
	sed -i "s|<core>parallel_n64_32b</core>|<core default=\"true\">parallel_n64_32b</core>|g" ${CORESFILE}
fi

}

post_install() {
	enable_service emustation.service
	mkdir -p ${INSTALL}/usr/share
	ln -sf /storage/.config/emuelec/configs/locale ${INSTALL}/usr/share/locale
	mkdir -p ${INSTALL}/usr/bin/batocera/
	ln -sf /usr/bin/7zr ${INSTALL}/usr/bin/batocera/7zr
}
