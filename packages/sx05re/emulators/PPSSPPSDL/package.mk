# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="PPSSPPSDL"
PKG_VERSION="f8261ae7ff93baa30f94214965547ed0f124da14"
PKG_REV="1"
PKG_ARCH="any"
PKG_LICENSE="MAME"
PKG_SITE="https://github.com/hrydgard/ppsspp"
PKG_URL="https://github.com/hrydgard/ppsspp.git"
# NOTE(w2xg2022): libglvnd原本是為了補PPSSPP的libOpenGL.so.0依賴加的，但ldd
# 確認PPSSPPSDL根本沒有直接連結libOpenGL.so(誤診)，而libglvnd會把系統的
# libEGL.so.1/libGLESv2.so.2 symlink從Mali改指向它自己沒設定vendor config
# 的dispatcher，導致ES/RA整個顯示初始化失敗(Could not get EGL display)。拿掉。
PKG_DEPENDS_TARGET="toolchain ffmpeg libzip libpng SDL2 zlib zip"
PKG_SHORTDESC="PPSSPPDL"
PKG_LONGDESC="PPSSPP Standalone"
GET_HANDLER_SUPPORT="git"
PKG_BUILD_FLAGS="-lto"


# NOTE(w2xg2022): 原本USING_FBDEV=ON直接畫/dev/fb0，會踩到廠商BSP核心同一顆
# Mali/framebuffer驅動的指標同步bug(實機驗證：fb0/fb1內容完全沒變化、process
# 卡住燒CPU，跟之前修好的PSP音效ALSA MMAP是同一家廠商驅動的同類問題)。改用
# EGL/DRM，跟ES/RA現在走的同一條已驗證沒問題的路徑(透過Mali)，繞開fbdev這條
# 有bug的路。
PKG_CMAKE_OPTS_TARGET+="-DUSE_SYSTEM_FFMPEG=ON \
                        -DUSING_FBDEV=OFF \
                        -DUSING_EGL=ON \
                        -DUSING_GLES2=ON \
                        -DUSING_X11_VULKAN=OFF \
                        -DUSE_DISCORD=OFF"

if [ ${ARCH} == "aarch64" ]; then
PKG_CMAKE_OPTS_TARGET+=" -DARM64=ON"
else
PKG_CMAKE_OPTS_TARGET+=" -DARMV7=ON"
fi


pre_configure_target() {
if [ "${DEVICE}" == "OdroidGoAdvance" ] || [ "${DEVICE}" == "GameForce" ]; then
	sed -i "s|include_directories(/usr/include/drm)|include_directories(${SYSROOT_PREFIX}/usr/include/drm)|" ${PKG_BUILD}/CMakeLists.txt
fi
}

pre_make_target() {
  # fix cross compiling
  find ${PKG_BUILD} -name flags.make -exec sed -i "s:isystem :I:g" \{} \;
  find ${PKG_BUILD} -name build.ninja -exec sed -i "s:isystem :I:g" \{} \;
}


makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
    cp ${PKG_DIR}/scripts/*.sh ${INSTALL}/usr/bin
    cp `find . -name "PPSSPPSDL" | xargs echo` ${INSTALL}/usr/bin/PPSSPPSDL
    ln -sf /storage/.config/ppsspp/assets ${INSTALL}/usr/bin/assets
    mkdir -p ${INSTALL}/usr/config/ppsspp/
    cp -r `find . -name "assets" | xargs echo` ${INSTALL}/usr/config/ppsspp/
    
    cp -rf ${PKG_DIR}/config/* ${INSTALL}/usr/config/ppsspp/
    
    rm ${INSTALL}/usr/config/ppsspp/assets/gamecontrollerdb.txt
    ln -sf /storage/.config/SDL-GameControllerDB/gamecontrollerdb.txt ${INSTALL}/usr/config/ppsspp/assets/gamecontrollerdb.txt
    
# redirect some of PSP folders to /storage/roms to keep all the saves and custom files
   mkdir -p "${INSTALL}/usr/config/ppsspp/PSP"    
   
for dir in Cheats PPSSPP_STATE SAVEDATA TEXTURES; do
		ln -sf "/storage/roms/savestates/PPSSPPSDL/PSP/${dir}" "${INSTALL}/usr/config/ppsspp/PSP/${dir}"
done
} 
