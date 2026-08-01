# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2018-present 5schatten (https://github.com/5schatten)
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2022-present 7Ji (https://github.com/7Ji)

PKG_NAME="SDL2"
PKG_VERSION="2.32.10"
#PKG_SHA256="332cb37d0be20cb9541739c61f79bae5a477427d79ae85e352089afdaf6666e4"
PKG_LICENSE="GPL"
PKG_SITE="https://www.libsdl.org/"
PKG_URL="https://www.libsdl.org/release/SDL2-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain alsa-lib systemd dbus ${OPENGLES} pulseaudio"
PKG_LONGDESC="Simple DirectMedia Layer is a cross-platform development library designed to provide low level access to audio, keyboard, mouse, joystick, and graphics hardware."
PKG_DEPENDS_HOST="toolchain:host distutilscross:host"
PKG_CMAKE_OPTS_HOST="-DSDL_MALI=OFF -DSDL_KMSDRM=OFF -DSDL_X11=OFF"

PKG_CMAKE_OPTS_TARGET="-DSDL_STATIC=OFF \
                       -DSDL_LIBC=ON \
                       -DSDL_GCC_ATOMICS=ON \
                       -DSDL_ALTIVEC=OFF \
                       -DSDL_OSS=OFF \
                       -DSDL_ALSA=ON \
                       -DSDL_ALSA_SHARED=ON \
                       -DSDL_JACK=OFF \
                       -DSDL_JACK_SHARED=OFF \
                       -DSDL_ESD=OFF \
                       -DSDL_ESD_SHARED=OFF \
                       -DSDL_ARTS=OFF \
                       -DSDL_ARTS_SHARED=OFF \
                       -DSDL_NAS=OFF \
                       -DSDL_NAS_SHARED=OFF \
                       -DSDL_LIBSAMPLERATE=OFF \
                       -DSDL_LIBSAMPLERATE_SHARED=OFF \
                       -DSDL_SNDIO=OFF \
                       -DSDL_DISKAUDIO=OFF \
                       -DSDL_DUMMYAUDIO=OFF \
                       -DSDL_DUMMYVIDEO=OFF \
                       -DSDL_WAYLAND=OFF \
                       -DSDL_WAYLAND_QT_TOUCH=ON \
                       -DSDL_WAYLAND_SHARED=OFF \
                       -DSDL_COCOA=OFF \
                       -DSDL_DIRECTFB=OFF \
                       -DSDL_VIVANTE=OFF \
                       -DSDL_DIRECTFB_SHARED=OFF \
                       -DSDL_FUSIONSOUND=OFF \
                       -DSDL_FUSIONSOUND_SHARED=OFF \
                       -DSDL_PTHREADS=ON \
                       -DSDL_PTHREADS_SEM=ON \
                       -DSDL_DIRECTX=OFF \
                       -DSDL_CLOCK_GETTIME=OFF \
                       -DSDL_RPATH=OFF \
                       -DSDL_RENDER_D3D=OFF \
                       -DSDL_X11=OFF \
                       -DSDL_OPENGLES=ON \
                       -DSDL_VULKAN=OFF \
                       -DSDL_PULSEAUDIO=ON \
                       -DSDL_HIDAPI_JOYSTICK=OFF"

case "${DEVICE}" in
  'Amlogic-ng'|'Amlogic-no'|'Amlogic-old')  # We should've used PROJECT=Amlogic-ce logically, but using these two device names here saves a comparasion (only device needs to be compared)
    PKG_PATCH_DIRS="Amlogic"
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_MALI=ON -DSDL_KMSDRM=OFF"
  ;;
  'RK3566'|'MD1000')
    # RK3566(MD1000)与上面那组同为 Rockchip/Mali,但用户空间用 device 层自带的
    # libmali(g24p0),内核侧 kbase 由 device 层的 linux-drivers/mali-bifrost 提供。
    #
    # ★2026-08-01:分支名从 'MD1000' 改成 'RK3566' —— 原本是【死码】★
    # device 目录改名后 DEVICE 已经是 RK3566,这个 case 再也没命中过,于是
    # PKG_PATCH_DIRS="Rockchip"(Rockchip 专属 SDL patch)与 -DSDL_KMSDRM=ON
    # 全都没套用。之所以没爆是因为 cmake 在 sysroot 里自动侦测到 libdrm/gbm,
    # 把 KMSDRM 顺手开了 —— 是碰巧,不是设计。两个名字都留着,避免再踩一次。
    # (机型名不一致的坑:运行期 EE_DEVICE 取自 /ee_arch,现在也是 RK3566。)
    #
    # ★SDL_VULKAN=ON 的理由★:PPSSPP 侦测到 Vulkan 驱动可用之后会【自己改用
    # Vulkan】,不管 ppsspp.ini 里 GraphicsBackend 写什么;此时 SDL 若没有
    # KMSDRM 的 Vulkan 后端就直接:
    #     Error creating SDL window: Vulkan support is either not configured in
    #     SDL or not available in current SDL video driver (KMSDRM) or platform
    #     terminate called without an active exception   → exit 134
    # 也就是说【连 OpenGL 都回不去】,PSP 整个不能用。判定方法:
    #     strings libSDL2-2.0.so.0.* | grep -c KMSDRM_Vulkan_   # 0 = 没编进去
    # ★只在本机型开★:Amlogic 那三台目前是验证过能跑的状态,没有 Vulkan 驱动,
    # 没有理由为了这台去动它们的 SDL。
    # 注:上面 PKG_CMAKE_OPTS_TARGET 里有 -DSDL_VULKAN=OFF,这里后附的 =ON
    # 排在命令行更后面,cmake 取最后一个,故覆盖成立。
    PKG_PATCH_DIRS="Rockchip"
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_KMSDRM=ON -DSDL_VULKAN=ON"
    PKG_DEPENDS_TARGET+=" libdrm libmali vulkan-headers vulkan-loader"
  ;;
  'OdroidGoAdvance'|'GameForce'|'RK356x'|'OdroidM1')
    PKG_PATCH_DIRS="Rockchip"
    PKG_CMAKE_OPTS_TARGET+=" -DSDL_KMSDRM=ON"
    PKG_DEPENDS_TARGET+=" libdrm mali-bifrost"
    if [ "${DEVICE}" = "OdroidGoAdvance" ]; then
      PKG_PATCH_DIRS+=" OdroidGoAdvance"
      PKG_DEPENDS_TARGET+=" librga"
      # This is evil, but we save multiple comparasions
      pre_make_host() {
        sed -i "s| -lrga||g" ${PKG_BUILD}/CMakeLists.txt
      }
      pre_make_target() {
        if ! `grep -rnw "${PKG_BUILD}/CMakeLists.txt" -e '-lrga'`; then
          sed -i "s|--no-undefined|--no-undefined -lrga|" ${PKG_BUILD}/CMakeLists.txt
        fi
      }
    fi
  ;;
esac


post_makeinstall_target() {
  sed -e "s:\(['=LI]\)/usr:\\1${SYSROOT_PREFIX}/usr:g" -i ${SYSROOT_PREFIX}/usr/bin/sdl2-config
  safe_remove ${INSTALL}/usr/bin
}
