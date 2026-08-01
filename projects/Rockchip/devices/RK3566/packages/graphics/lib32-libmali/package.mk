# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 w2xg2022

# 32 位的 libmali,给 EmuELEC 在 aarch64 上编的那批 32 位 libretro 核心用
# (lib32-retroarch / lib32-mupen64plus / lib32-flycast / lib32-SDL2 …
#  它们都写着 PKG_DEPENDS_TARGET="… lib32-${OPENGLES}")。
#
# 与 64 位的 device 层 libmali 同源同版本(g24p0),只是换成 armhf 的 .so。
# 安装布局照抄树里既有的 lib32-mali-bifrost:blob 放 /usr/lib32/libmali/,
# 再用 profile.d 把该目录追加到 LD_LIBRARY_PATH 尾部
# (放尾部是为了让 /emuelec/lib 先被搜到,这点也照原样保留)。
#
# 头文件仍取自 LibreELEC 的 libmali 仓库(标准 Khronos 头,与 blob 版本无关)。

PKG_NAME="lib32-libmali"
PKG_VERSION="d4000def121b818ae0f583d8372d57643f723fdc"
PKG_SHA256="4f2103fc927cc006ee5c9b647e899f50b0dcaeee127fec713387d06a333eb404"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/LibreELEC/libmali"
PKG_URL="https://github.com/LibreELEC/libmali/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="OpenGL ES user-space binary for ARM Mali G52 (g24p0), 32-bit"
PKG_TOOLCHAIN="manual"
PKG_BUILD_FLAGS="lib32"

PKG_DEPENDS_TARGET="lib32-toolchain lib32-libdrm"
PKG_NEED_UNPACK="$(get_pkg_directory libmali-g52-blob32)"

post_unpack() {
  ${SCRIPTS}/get libmali-g52-blob32
  cp -a "${SOURCES}/libmali-g52-blob32/$(get_pkg_variable libmali-g52-blob32 PKG_SOURCE_NAME)" \
        "${PKG_BUILD}/libmali32.so"
}

makeinstall_target() {
  local LIBDIR=${INSTALL}/usr/lib32/libmali

  mkdir -p ${LIBDIR} \
           ${SYSROOT_PREFIX}/usr/lib/pkgconfig \
           ${SYSROOT_PREFIX}/usr/include/KHR

  mkdir -p ${INSTALL}/etc/profile.d
  # 追加在既有 LD_LIBRARY_PATH 之后,确保 /emuelec/lib 优先被搜到
  echo 'export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/lib32/libmali"' \
    > ${INSTALL}/etc/profile.d/99-rk-mali-workaround.conf

  cp ${PKG_BUILD}/libmali32.so ${LIBDIR}/libmali.so
  cp ${PKG_BUILD}/libmali32.so ${SYSROOT_PREFIX}/usr/lib/libmali.so

  local LINK_LIST="libEGL.so libEGL.so.1 \
                   libgbm.so libgbm.so.1 \
                   libGLESv2.so libGLESv2.so.2 \
                   libGLESv3.so libGLESv3.so.3 \
                   libGLESv1_CM.so libGLESv1_CM.so.1 \
                   libGLES_CM.so.1 \
                   libmali.so.1"
  local LINK_NAME
  for LINK_NAME in ${LINK_LIST}; do
    ln -sf libmali.so ${LIBDIR}/${LINK_NAME}
    ln -sf libmali.so ${SYSROOT_PREFIX}/usr/lib/${LINK_NAME}
  done

  # 标准 Khronos 头(来自 LibreELEC libmali 仓库)
  cp -r ${PKG_BUILD}/include/EGL ${PKG_BUILD}/include/GLES ${PKG_BUILD}/include/GLES2 \
        ${PKG_BUILD}/include/GLES3 ${PKG_BUILD}/include/KHR ${SYSROOT_PREFIX}/usr/include/
  # 与 64 位那份 libmali 同样的理由:LibreELEC 仓库里的 gbm.h 是 r16p0 年代的,
  # 缺 GBM_BO_USE_LINEAR,SDL2 2.32 的 kmsdrm 后端会编不过。
  # 复用 ../libmali/files/gbm.h(取自 blob 仓库 include/GBM/23.1.3)。
  cp ${PKG_DIR}/../libmali/files/gbm.h ${SYSROOT_PREFIX}/usr/include/gbm.h

  # gbm 版本号跟 Mesa 走(RetroArch 的 configure 要求 gbm >= 9.0),
  # 与 64 位那份 libmali 保持一致,详见其注释。
  local _pc
  for _pc in egl:EGL:1.4 glesv2:GLESv2:2.0 glesv1_cm:GLESv1_CM:1.1 gbm:gbm:23.1.3; do
    local _name="${_pc%%:*}" _rest="${_pc#*:}"
    local _lib="${_rest%%:*}" _ver="${_rest##*:}"
    cat > ${SYSROOT_PREFIX}/usr/lib/pkgconfig/${_name}.pc <<EOF
prefix=/usr
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: ${_name}
Description: Mali ${_lib} library (g24p0, 32-bit)
Version: ${_ver}
Libs: -L\${libdir} -l${_lib}
Libs.private: -lm -lpthread
Cflags: -I\${includedir}
EOF
  done
}
