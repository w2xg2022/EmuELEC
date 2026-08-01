# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-2022 Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="lib32-glibc"
PKG_VERSION="$(get_pkg_version glibc)"
PKG_NEED_UNPACK="$(get_pkg_directory glibc)"
PKG_ARCH="aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://www.gnu.org/software/libc/"
PKG_URL=""
PKG_DEPENDS_TARGET="ccache:host autotools:host lib32-linux-headers lib32-gcc:bootstrap pigz:host glibc Python3:host" # Make sure both 64 and 32 are built
PKG_LONGDESC="The Glibc package contains the main C library, for multilib ARM."
GLIBC_DIRECTORY="$(get_pkg_directory glibc)"
PKG_NEED_UNPACK+=" ${GLIBC_DIRECTORY}"
# NOTE(w2xg2022): 刻意**不套** ${GLIBC_DIRECTORY}/patches/arm 那三个补丁。
#
# 那组补丁是给 Amlogic 4.9 内核用的:
#   0003 把 sysdeps/unix/sysv/linux/arm/arch-syscall.h 里的
#        `#define __NR_statx 397` 注解掉(4.9 内核没有 statx 系统调用);
#   0001 把 statx.c 改成 __NR_statx 未定义时回退到 statx_generic。
#
# 但 0001 改完的结构是:
#   #ifdef __NR_statx  …  # ifdef __ASSUME_STATX  return ret;  # endif  #endif
#   #ifndef __ASSUME_STATX  return statx_generic(…);  #endif
# 当「__NR_statx 未定义」且「__ASSUME_STATX 已定义」时函数体是**空的**,
# gcc 报 control reaches end of non-void function [-Werror=return-type]。
#
# __ASSUME_STATX 的门槛是 --enable-kernel >= 4.11
# (sysdeps/unix/sysv/linux/kernel-features.h:117)。MD1000 的 LINUX=rk356x-6.6
# 落到下面 case 的 *) 分支 = 6.1.0,必然定义 __ASSUME_STATX,于是与 0003 冲突。
#
# MD1000 内核是 6.6,statx 自 4.11 起就存在,那组补丁对我们没有意义也不该套。
# 排除后使用上游原版 statx.c,__NR_statx 保持定义,语义正确。
PKG_PATCH_DIRS+=" ${GLIBC_DIRECTORY}/patches"
PKG_BUILD_FLAGS="-gold lib32"

case "${LINUX}" in
  amlogic-4.9|rk356x-4.19|OdroidM1-4.19)
    OPT_ENABLE_KERNEL=4.9.0
    ;;
  gameforce-4.4|rockchip-4.4|odroid-go-a-4.4)
    OPT_ENABLE_KERNEL=4.4.0
    ;;
  amlogic-5.15)
    OPT_ENABLE_KERNEL=5.15.0
    ;;
  amlogic-5.4)
    OPT_ENABLE_KERNEL=5.4.0
    ;;
  amlogic-3.14)
    OPT_ENABLE_KERNEL=3.0.0
    ;;
  *)
    OPT_ENABLE_KERNEL=6.1.0
    ;;
esac

PKG_CONFIGURE_OPTS_TARGET="BASH_SHELL=/bin/sh \
                           ac_cv_path_PERL=no \
                           ac_cv_prog_MAKEINFO= \
                           --libexecdir=/usr/lib/glibc \
                           --cache-file=config.cache \
                           --disable-profile \
                           --disable-sanity-checks \
                           --enable-add-ons \
                           --enable-bind-now \
                           --with-elf \
                           --with-tls \
                           --with-__thread \
                           --with-binutils=${BUILD}/toolchain/bin \
                           --with-headers=${LIB32_SYSROOT_PREFIX}/usr/include \
                           --enable-kernel=${OPT_ENABLE_KERNEL} \
                           --without-cvs \
                           --without-gd \
                           --disable-build-nscd \
                           --disable-nscd \
                           --disable-timezone-tools"

if build_with_debug; then
  PKG_CONFIGURE_OPTS_TARGET+=" --enable-debug"
else
  PKG_CONFIGURE_OPTS_TARGET+=" --disable-debug"
fi

unpack() {
  ${SCRIPTS}/get glibc
  mkdir -p ${PKG_BUILD}
  tar --strip-components=1 -xf ${SOURCES}/glibc/glibc-${PKG_VERSION}.tar.xz -C ${PKG_BUILD}
}

post_unpack() {
  find "${PKG_BUILD}" -type f -name '*.py' -exec sed -e '1s,^#![[:space:]]*/usr/bin/python.*,#!/usr/bin/env python3,' -i {} \;
}

pre_configure_target() {
# Filter out some problematic *FLAGS
  export CFLAGS=$(echo ${CFLAGS} | sed -e "s|-ffast-math||g")
  export CFLAGS=$(echo ${CFLAGS} | sed -e "s|-Ofast|-O2|g")
  export CFLAGS=$(echo ${CFLAGS} | sed -e "s|-O.|-O2|g")

  export CFLAGS=$(echo ${CFLAGS} | sed -e "s|-Wunused-but-set-variable||g")
  export CFLAGS="${CFLAGS} -Wno-unused-variable"

  if [ -n "${PROJECT_CFLAGS}" ]; then
    export CFLAGS=$(echo ${CFLAGS} | sed -e "s|${PROJECT_CFLAGS}||g")
  fi

  export LDFLAGS=$(echo ${LDFLAGS} | sed -e "s|-ffast-math||g")
  export LDFLAGS=$(echo ${LDFLAGS} | sed -e "s|-Ofast|-O2|g")
  export LDFLAGS=$(echo ${LDFLAGS} | sed -e "s|-O.|-O2|g")

  export LDFLAGS=$(echo ${LDFLAGS} | sed -e "s|-Wl,--as-needed||")

  unset LD_LIBRARY_PATH

  # set some CFLAGS we need
  export CFLAGS="${CFLAGS} -g -fno-stack-protector"

  export BUILD_CC=${HOST_CC}
  export OBJDUMP_FOR_HOST=objdump

  cat >config.cache <<EOF
libc_cv_forced_unwind=yes
libc_cv_c_cleanup=yes
libc_cv_ssp=no
libc_cv_ssp_strong=no
libc_cv_slibdir=/usr/lib
EOF

  cat >configparms <<EOF
libdir=/usr/lib
slibdir=/usr/lib
sbindir=/usr/bin
rootsbindir=/usr/bin
build-programs=no
EOF

}

post_makeinstall_target() {
  safe_remove ${INSTALL}/etc
  safe_remove ${INSTALL}/usr/bin
  safe_remove ${INSTALL}/usr/include
  safe_remove ${INSTALL}/usr/lib/audit
  safe_remove ${INSTALL}/usr/lib/*.o
  safe_remove ${INSTALL}/usr/share
  safe_remove ${INSTALL}/var
  mkdir -p "${INSTALL}/etc/ld.so.conf.d"
    echo "/usr/lib32" > "${INSTALL}/etc/ld.so.conf.d/lib32-glibc.conf"
    # printf "/emuelec/lib32\n/emuelec/lib\n" > "${INSTALL}/etc/ld.so.conf.d/emuelec.conf"
  mv ${INSTALL}/usr/lib ${INSTALL}/usr/lib32
}
