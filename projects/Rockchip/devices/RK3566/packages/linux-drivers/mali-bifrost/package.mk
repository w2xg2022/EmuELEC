# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 w2xg2022

# MD1000 (RK3566 / Mali-G52) 专用的 Mali kbase —— ★device 层覆盖★
#
# 为什么要覆盖全局那份 packages/linux-drivers/mali-bifrost：
#   全局那份是 LibreELEC 的 r16p0(2018 年的 BX301A01B)，只编得动 4.19/5.x，
#   而且它的 make_target 走的是 config.meson-g12a 那套 Amlogic 平台后端。
#   我们是 mainline 6.18 + Rockchip，两边都对不上。
#   ★不能改全局那份★：Amlogic-ce 系(X98mini / E900V22C)还在用它。
#
# 这份的来源与配对，★整组照抄 ROCKNIX 的 RK3566★(实机验证过的组合)：
#   projects/ROCKNIX/packages/linux-drivers/mali-bifrost/package.mk
#     kbase   = rocknix/mali_kbase @ 39da994b, MALI_PLATFORM=devicetree
#   projects/ROCKNIX/packages/graphics/libmali/package.mk
#     blob    = g24p0   ("*) # RK3326 and RK3566" 那一支)
#   我们 device 层的 packages/graphics/libmali 用的正好也是 g24p0，
#   所以 kbase 与 user-space blob 是 ROCKNIX 已经配好的那一对，不是新凑的。
#   (★Mali 的 blob 必须与内核 kbase 版本相容★，换任何一边都要重做配对验证。)
#
# ★不用改 dts★：kbase 的 of_device_id 里有 "arm,mali-bifrost"
#   (product/kernel/drivers/gpu/arm/midgard/mali_kbase_core_linux.c)，
#   而我们那份 mainline dts 的 GPU 节点写的就是
#     compatible = "rockchip,rk3568-mali", "arm,mali-bifrost";
#   直接就绑得上。dts 一个字都不用动 —— 那份 dts 与 Armbian 的 dtb 逐字节相同，
#   AV(3.5mm)能出声就是靠它，动不得。
#
# ★配套必须关掉 CONFIG_DRM_PANFROST / DRM_PANTHOR★：
#   panfrost 认的也是 "arm,mali-bifrost"，两个驱动抢同一个节点，
#   谁先 probe 谁赢 —— 这正是「静默失败」的典型形态。见 linux/md1000-6.18/。

PKG_NAME="mali-bifrost"
PKG_VERSION="39da994bb6fc8819e5e8c1873907dd21d17e53c1"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/rocknix/mali_kbase"
PKG_URL="https://github.com/rocknix/mali_kbase/archive/${PKG_VERSION}.tar.gz"
PKG_LONGDESC="mali-bifrost: Linux kernel driver (kbase) for ARM Mali Bifrost GPUs"
PKG_TOOLCHAIN="manual"
PKG_IS_KERNEL_PKG="yes"

make_target() {
  # devicetree 后端：GPU 的时钟与电源域交给内核的 power domain 驱动协调，
  # 这是 Rockchip 该用的那个(meson 后端是 Amlogic 专用)。
  kernel_make KDIR=$(kernel_path) -C ${PKG_BUILD} \
       CONFIG_MALI_MIDGARD=m \
       CONFIG_MALI_PLATFORM_NAME=devicetree \
       CONFIG_MALI_REAL_HW=y \
       CONFIG_MALI_DEVFREQ=y \
       CONFIG_MALI_GATOR_SUPPORT=y
}

makeinstall_target() {
  local DRIVER_DIR="${PKG_BUILD}/product/kernel/drivers/gpu/arm/midgard"
  [ -f "${DRIVER_DIR}/mali_kbase.ko" ] || \
    { echo "mali-bifrost: ERROR 没编出 mali_kbase.ko"; exit 1; }
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
  cp ${DRIVER_DIR}/mali_kbase.ko ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}
}
