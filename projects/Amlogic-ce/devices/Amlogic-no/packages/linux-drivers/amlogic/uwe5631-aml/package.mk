# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team CoreELEC (https://coreelec.org)

# NOTE(w2xg2022): Amlogic-no(5.15)專用override，只差PKG_VERSION/PKG_SHA256指向
# 上游linux-5.15分支(2025-11移植)，其餘內容與projects/Amlogic-ce/packages下的共用版相同。
# 共用版釘的是master的commit，那份源碼LINUX_VERSION_CODE判斷最高只到5.6，
# 拿去編5.15 vendor內核會炸在wcn_dump.o；linux-5.15分支才有5.15/5.17的適配。
# ng線(4.9)繼續吃共用版不受影響，所以不動共用版，改在device層覆蓋。
# 詳見記憶 e900v22c-5-15-adaptation。

PKG_NAME="uwe5631-aml"
PKG_VERSION="df31fe79d3a5875a23e1d7e25852e35de1c25e43"
PKG_SHA256="9db386ca6dbb7e52950c8d0671e8740d267b750ca87ea02b397fc5f90c807d50"
PKG_ARCH="arm aarch64"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/CoreELEC/uwe5631-aml"
PKG_URL="https://github.com/CoreELEC/uwe5631-aml/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux"
PKG_NEED_UNPACK="${LINUX_DEPENDS}"
PKG_LONGDESC="uwe5631-aml: Unisoc UWE5621 WIFI/BT driver"
PKG_IS_KERNEL_PKG="yes"
PKG_TOOLCHAIN="manual"

make_target() {
  echo "making WIFI"
  kernel_make -C ${PKG_BUILD} \
    M=${PKG_BUILD} \
    KERNEL_SRC=$(kernel_path) \
    EXTRA_CFLAGS="-fno-pic -Wno-sizeof-pointer-memaccess -Wno-declaration-after-statement -I${PKG_BUILD}/BSP/include -DCUSTOMIZE_WIFI_CFG_PATH=\\\"/lib/firmware/unisoc\\\"" \
    modules

  echo "making BT"
  kernel_make -C ${PKG_BUILD}/BT/tty-sdio \
    M=${PKG_BUILD}/BT/tty-sdio \
    KERNEL_SRC=$(kernel_path) \
    CURFOLDER=${PKG_BUILD}/BSP \
    modules
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/${PKG_NAME}

  find $PKG_BUILD/ -name \*.ko -not -path '*/\.*' \
    -exec cp {} ${INSTALL}/$(get_full_module_dir)/${PKG_NAME} \;

  mkdir -p ${INSTALL}/$(get_kernel_overlay_dir)/lib/firmware/unisoc

  cp -av ${PKG_DIR}/firmware/*.ini \
         ${PKG_BUILD}/BT/libbt/conf/sprd/runtime/*.ini \
         ${PKG_BUILD}/BSP/fw/wcnmodem.bin \
    ${INSTALL}/$(get_kernel_overlay_dir)/lib/firmware/unisoc
}
