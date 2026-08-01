# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2026 w2xg2022

# MD1000 专用的 libmali:GLES/EGL/GBM 用户空间换成 g24p0。
#
# 与全局 packages/graphics/libmali 的差别:
#   1. blob 从 r16p0 换成 g24p0(理由见 libmali-g52-blob/package.mk)。
#   2. 不再依赖 linux-drivers/mali-bifrost —— 那是 r16p0 的 out-of-tree kbase,
#      6.6 vendor BSP 树内已经有 CONFIG_MALI_BIFROST=y(g25p0),再编一份会打架。
#   3. 不走 cmake:上游那份 CMakeLists 只认得 r16p0 的文件名。
#
# 头文件与 pkgconfig 仍取自 LibreELEC 的 libmali 仓库(那是标准 Khronos 头,
# 与 blob 版本无关),blob 则来自 libmali-g52-blob —— 这种"主源 + 额外源"的写法
# 照抄树里 packages/linux/package.mk 抓 exfat-linux 的既有模式。

PKG_NAME="libmali"
PKG_VERSION="d4000def121b818ae0f583d8372d57643f723fdc"
PKG_SHA256="4f2103fc927cc006ee5c9b647e899f50b0dcaeee127fec713387d06a333eb404"
PKG_ARCH="aarch64"
PKG_LICENSE="nonfree"
PKG_SITE="https://github.com/LibreELEC/libmali"
PKG_URL="https://github.com/LibreELEC/libmali/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="OpenGL ES user-space binary for the ARM Mali GPU family (G52 g24p0)"
PKG_TOOLCHAIN="manual"
PKG_STAMP="${MALI_FAMILY}"

PKG_DEPENDS_TARGET="toolchain libdrm"
PKG_NEED_UNPACK="$(get_pkg_directory libmali-g52-blob)"

MALI_BLOB="libmali-bifrost-g52-g24p0-gbm.so"

post_unpack() {
  # 取回 g24p0 的 .deb 并解出 blob(deb = ar 包,里面是 data.tar.zst)
  ${SCRIPTS}/get libmali-g52-blob

  local _deb="${SOURCES}/libmali-g52-blob/$(get_pkg_variable libmali-g52-blob PKG_SOURCE_NAME)"
  local _tmp="${PKG_BUILD}/.blob"

  rm -rf "${_tmp}"
  mkdir -p "${_tmp}"
  ( cd "${_tmp}" && ar x "${_deb}" && tar -xf data.tar.zst )

  # deb 里主文件叫 libmali.so.1.9.0,同目录还有个同名软链 libmali-bifrost-g52-g24p0-gbm.so
  cp -a "${_tmp}/usr/lib/aarch64-linux-gnu/libmali.so.1.9.0" "${PKG_BUILD}/${MALI_BLOB}"
  # hook 库:某些应用要靠它拿到被包装过的函数(ROCKNIX 实机上也带了这个)
  cp -a "${_tmp}/usr/lib/aarch64-linux-gnu/libmali-hook.so.1.9.0" "${PKG_BUILD}/" || true
}

_install_symlinks() {
  # $1 = 安装根目录, $2 = blob 的运行期绝对路径
  local _root="$1" _blob="$2" _l
  # 注意 libGLESv3:blob 把 GLES 1/2/3 全实现在同一个 .so 里,但 EmuELEC 里
  # 有套件直接 -lGLESv3(例如 mupen64plus-nx-alt),没有这个软链会
  # "ld.gold: error: cannot find -lGLESv3"。树内 Amlogic 的 opengl-meson
  # 与 lib32-mali-bifrost 都建了这组,这里对齐。
  for _l in libmali.so libmali.so.1 libMali.so \
            libEGL.so libEGL.so.1 \
            libGLESv1_CM.so libGLESv1_CM.so.1 libGLES_CM.so.1 \
            libGLESv2.so libGLESv2.so.2 \
            libGLESv3.so libGLESv3.so.3 \
            libgbm.so libgbm.so.1; do
    ln -sfv "${_blob}" "${_root}/usr/lib/${_l}"
  done
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib
  cp -a ${PKG_BUILD}/${MALI_BLOB} ${INSTALL}/usr/lib/
  [ -f ${PKG_BUILD}/libmali-hook.so.1.9.0 ] && \
    cp -a ${PKG_BUILD}/libmali-hook.so.1.9.0 ${INSTALL}/usr/lib/ && \
    ln -sfv /usr/lib/libmali-hook.so.1.9.0 ${INSTALL}/usr/lib/libmali-hook.so.1
  _install_symlinks "${INSTALL}" "/usr/lib/${MALI_BLOB}"

  # 同一份也进 sysroot,给交叉编译期链接用(照 opengl-meson 的做法)
  mkdir -p ${SYSROOT_PREFIX}/usr/lib ${SYSROOT_PREFIX}/usr/include ${SYSROOT_PREFIX}/usr/lib/pkgconfig
  cp -a ${PKG_BUILD}/${MALI_BLOB} ${SYSROOT_PREFIX}/usr/lib/
  _install_symlinks "${SYSROOT_PREFIX}" "${SYSROOT_PREFIX}/usr/lib/${MALI_BLOB}"

  # 标准 Khronos 头文件(来自 LibreELEC libmali 仓库,与 blob 版本无关)
  cp -r ${PKG_BUILD}/include/EGL ${PKG_BUILD}/include/GLES ${PKG_BUILD}/include/GLES2 \
        ${PKG_BUILD}/include/GLES3 ${PKG_BUILD}/include/KHR ${SYSROOT_PREFIX}/usr/include/

  # gbm.h 不能用 LibreELEC 那份 —— 它是 r16p0 年代的,缺 GBM_BO_USE_LINEAR,
  # SDL2 2.32 的 src/video/kmsdrm/SDL_kmsdrmmouse.c:110 会编不过。
  # 改用与 g24p0 blob 同源的那份(仓库 include/GBM/23.1.3/gbm.h,对应 Mesa GBM
  # API 23.1.3),已随包收进 files/,不在构建期联网。
  cp ${PKG_DIR}/files/gbm.h ${SYSROOT_PREFIX}/usr/include/gbm.h

  # pkgconfig:上游是 cmake 模板,这里直接写死(prefix 固定 /usr)
  # gbm 的版本号要跟 **Mesa 版本** 走,不是 GBM API 的 1.0。
  # RetroArch 的 qb/config.libs.sh 里写死了 `check_val '' GBM -lgbm '' gbm 9.0`,
  # 即要求 gbm >= 9.0;填 1.0 会被判定不符,configure 直接报
  # "Error: GBM is disabled and forced to build with KMS support."
  # 我们装的头文件取自仓库 include/GBM/23.1.3,所以这里对齐写 23.1.3。
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
Description: Mali ${_lib} library (g24p0)
Version: ${_ver}
Libs: -L\${libdir} -l${_lib}
Libs.private: -lm -lpthread
Cflags: -I\${includedir}
EOF
  done
}
