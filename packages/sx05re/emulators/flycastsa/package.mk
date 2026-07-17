# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2021-present Shanti Gilbert (https://github.com/shantigilbert)

PKG_NAME="flycastsa"
PKG_VERSION="bf2bd7efed41e9f3367a764c2d90fcaa9c38a1f9"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/flyinghead/flycast"
PKG_URL="${PKG_SITE}.git"
# NOTE(w2xg2022): 补上 curl —— CMakeLists.txt:495 的 find_package(CURL) 是硬需求。
# 全量建置时 curl 碰巧被别的套件先编好,所以这个漏宣告一直没暴露;单独编本包(例如
# EmuELEC-prebuilt-cores 仓库跑 ./scripts/build flycastsa:target)就会
# 「Could NOT find CURL (missing: CURL_LIBRARY CURL_INCLUDE_DIR)」configure 直接失败。
PKG_DEPENDS_TARGET="toolchain ${OPENGLES} alsa SDL2 libzip zip curl"
PKG_LONGDESC="Flycast is a multiplatform Sega Dreamcast, Naomi and Atomiswave emulator"
PKG_TOOLCHAIN="cmake"
PKG_GIT_CLONE_BRANCH="master"


if [ "${ARCH}" == "arm" ]; then
	PKG_PATCH_DIRS="arm"
fi

pre_configure_target() {
export CXXFLAGS="${CXXFLAGS} -Wno-error=array-bounds"
PKG_CMAKE_OPTS_TARGET+="-DUSE_GLES=ON -DUSE_VULKAN=OFF -DUSE_HOST_SDL=ON"
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/bin
  cp ${PKG_BUILD}/.${TARGET_NAME}/flycast ${INSTALL}/usr/bin/flycast
  cp ${PKG_DIR}/scripts/* ${INSTALL}/usr/bin

	chmod +x ${INSTALL}/usr/bin/flycast.sh
	chmod +x ${INSTALL}/usr/bin/set_flycast_joy.sh
}
