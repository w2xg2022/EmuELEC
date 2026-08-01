# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)
# Copyright (C) 2026 w2xg2022

# Mali-G52 的 Vulkan 用户空间 blob。
#
# 注意:Vulkan 是**独立 blob**,不在 JeffyCN/tsukumijima 那套 libmali 仓库里
# (那边只有 GLES 的 libmali-bifrost-g52-*.so,全树没有任何 vulkan 文件)。
#
# ★2026-08-01:blob 从 rk3576 换成 g52_vulkan —— 原因是【挑错变体】★
#
# 旧值抓的是 sydarn/libmali 的 rk3576 release,那颗是 **Wayland 变体**:
#     ldd libmali-vulkan-g52.so
#       libwayland-client.so.0 => not found
#       libwayland-server.so.0 => not found
# 而 EmuELEC 走 DRM/KMS,整棵树【没有】Wayland。于是 loader 连 ICD 都载不进去:
#     ERROR: loader_icd_scan: Failed loading library associated with ICD JSON
#     ERROR: vkCreateInstance: Found no drivers!
#     vkCreateInstance = -9  (VK_ERROR_INCOMPATIBLE_DRIVER)
# 症状是 **PPSSPP 的「渲染引擎」下拉只有 OpenGL、没有 Vulkan** ——
# 不是 PPSSPP 没编 Vulkan(二进位里有 193 个 vulkan 字串),是它探测不到可用驱动。
#
# ★修法是把变体挑回来,不是去把 Wayland 引进树里★
# 隔壁 packages/graphics/libmali(GLES)本来就刻意用 -gbm 非 Wayland 变体,
# 是这个 package 破了例。给树加 wayland 依赖看似只有一行,但那会让 wayland
# 进 sysroot —— 干净编译时 SDL2/mesa 这类会自动侦测依赖的套件就可能把
# Wayland 后端编进去,是不报错、行为悄悄变掉的那种改动。不划算。
#
# 新 blob (g52_vulkan release 的 libmali.so) 已逐项验证:
#   - readelf -d:相依只有 libdrm/libpthread/libdl/libstdc++/libm/libc/libgcc_s
#                 ★没有任何 wayland★
#   - 匯出三个 ICD 进入点:vk_icdNegotiateLoaderICDInterfaceVersion /
#                          vk_icdGetInstanceProcAddr / vk_icdGetPhysicalDeviceProcAddr
#     (ICD 不必匯出 vkCreateInstance,只匯出 vk_icd* 就是合格 ICD——
#      别拿 vkCreateInstance 去 grep 然后误判「这颗没有 Vulkan」)
#   - api_version 1.3.276
#
# ★这颗其实是 GLES+EGL+Vulkan 合一的 blob★(里面也有 glDrawArrays/eglGetDisplay)。
# 理论上可以拿它一颗取代 GLES 那颗、省下约 57MB,但**本轮刻意不做**:
# 那等于同时换掉现在唯一确定能动的 GLES 驱动,还要重验 blob 与 kbase 的相容性。
# 一次只解一件。
#
# ★release 里还附了一颗 libvulkan.so.1.3.274(loader),不要用★:
# 树里已经有 vulkan-loader 1.3.241。loader 版本低于 ICD 宣告的 api 没关系,
# loader 会自己收敛;换掉它反而多一个变数。

PKG_NAME="libmali-vulkan"
PKG_VERSION="g52_vulkan"
PKG_SHA256="9cce12a8eb37da7c033bf9132f51ac986f0ce150d33e96dee2ce46604a1ee008"
PKG_ARCH="aarch64"
PKG_LICENSE="mali_driver"
PKG_SITE="https://github.com/sydarn/libmali"
PKG_URL="https://github.com/sydarn/libmali/releases/download/${PKG_VERSION}/blobs.zip"
# ★PKG_SOURCE_NAME 必须跟着换名★:sources/ 是按这个档名做快取的,
# 沿用旧名会直接重用磁碟上那颗【旧的 Wayland 版】,改了等于没改。
PKG_SOURCE_NAME="g52-vulkan-mali-${PKG_VERSION}.zip"
PKG_DEPENDS_TARGET="toolchain vulkan-loader vulkan-headers"
PKG_TOOLCHAIN="manual"
PKG_LONGDESC="Vulkan Mali user-space driver for the RK3566 (Mali-G52)"

FILENAME="libmali-vulkan-g52.so"
APIVER="1.3.276"

# 解包脚本的 --strip-components=1 会把内容剥光,所以自己来。
# blobs.zip 里有 12 个档(GLES 各种 soname 的符号链接式副本 + libvulkan + icd.d),
# 只取 libmali.so 这一颗;它们的 icd.d/rk_vk.json 也不用,我们自己有 mali.json 模板。
unpack() {
  mkdir -p ${PKG_BUILD}
  unzip -j ${SOURCES}/${PKG_NAME}/${PKG_SOURCE_NAME} libmali.so -d ${PKG_BUILD}
  mv ${PKG_BUILD}/libmali.so ${PKG_BUILD}/${FILENAME}
  cp ${PKG_DIR}/mali.json ${PKG_BUILD}/mali.json
}

make_target() {
  sed -i "s~@APIVER@~${APIVER}~g" ${PKG_BUILD}/mali.json
  sed -i "s~@LIB@~/usr/lib/${FILENAME}~g" ${PKG_BUILD}/mali.json
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  mkdir -p ${INSTALL}/usr/share/vulkan/icd.d

  cp ${PKG_BUILD}/${FILENAME} ${INSTALL}/usr/lib/
  cp ${PKG_BUILD}/mali.json ${INSTALL}/usr/share/vulkan/icd.d/

  ln -sfv /usr/lib/${FILENAME} ${INSTALL}/usr/lib/libMaliVulkan.so.1
  ln -sfv /usr/lib/libMaliVulkan.so.1 ${INSTALL}/usr/lib/libMaliVulkan.so
}
