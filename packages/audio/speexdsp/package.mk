# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="speexdsp"
PKG_VERSION="1.2.1"
PKG_SHA256="b36d4f16e42b7103b7fc3e4a8f98b6bf889dd1f70f65c2365af07be82844db29"
PKG_LICENSE="BSD"
PKG_SITE="https://speex.org"
# NOTE(w2xg2022): gitlab.xiph.org回502，改用repo內自帶鏡像(源碼取自VM本地
# sources/快取，sha256驗證跟本檔案記錄的完全一致，正版原始檔案)。
PKG_URL="https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/packages/audio/speexdsp/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="Speex audio processing library"
PKG_TOOLCHAIN="autotools"
