# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2022-present Team CoreELEC (https://coreelec.org)

PKG_NAME="gcc7-linaro-aarch64-elf"
PKG_VERSION="7.5.0-2019.12"
PKG_SHA256="73689fb3e71beeecebd6434d60efad4cb926153d48399e4d16fb45395d9c81a0"
PKG_LICENSE="GPL"
PKG_SITE="https://www.linaro.org/"
# NOTE(w2xg2022): releases.linaro.org連線逾時(GitHub Actions runner測試確認)，
# 改用sources.coreelec.org鏡像，實測sha256完全吻合，且是CoreELEC官方自己的
# 鏡像站(這個package.mk header本身就是CoreELEC的)，不用把54MB塞進repo。
PKG_URL="https://sources.coreelec.org/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_HOST="ccache:host"
PKG_LONGDESC="Linaro Aarch64 GNU Linux Binary Toolchain"
PKG_TOOLCHAIN="manual"

unpack() {
  mkdir -p ${PKG_BUILD}
  mkdir -p ${TOOLCHAIN}/lib/${PKG_NAME}

  tar --strip-components=1 -xf ${SOURCES}/${PKG_NAME}/${PKG_NAME}-${PKG_VERSION}.tar.xz -C ${TOOLCHAIN}/lib/${PKG_NAME}
}

makeinstall_host() {
  : # nothing, unpacked directly to toolchain
}
