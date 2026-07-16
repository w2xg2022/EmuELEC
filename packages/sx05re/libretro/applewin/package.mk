# SPDX-License-Identifier: GPL-2.0-or-later

PKG_NAME="applewin"
PKG_VERSION="f2c22675385a5c2561d7aec1cc8ecf860e20fc5d"
PKG_SHA256="365e262ed145b23cd79a9365cfab47c5d7b5e1625e867d337b534267a4c916fb"
PKG_ARCH="any"
PKG_LICENSE="GPLv2"
PKG_SITE="https://github.com/audetto/AppleWin"
PKG_URL="${PKG_SITE}/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="libretro"
PKG_SHORTDESC="libretro core for Apple II emulation (AppleWin libretro fork)"
PKG_TOOLCHAIN="cmake"

# NOTE(w2xg2022): repo原本只有applewin_libretro.info沒有實際.so，
# apple2系統預設指定的mame core也沒有編譯出.so(只有.info)，apple2完全玩不了。
# audetto/AppleWin是libretro官方推荐的apple2 core來源，BUILD_LIBRETRO是
# 唯一不需要Qt5/Boost的build選項(只有BUILD_QAPPLE才需要那些)。
pre_configure_target() {
  PKG_CMAKE_OPTS_TARGET+=" -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO=ON -DBUILD_QAPPLE=OFF -DBUILD_SA2=OFF -DBUILD_APPLEN=OFF"

# NOTE(w2xg2022): resource/Cousine-Regular.ttf在git倉庫裡是指向imgui submodule的
# symlink，archive.tar.gz下載不含submodule內容，解開後變成死連結，xxd讀不到檔案
# 導致build失敗。直接下載實際字體檔覆蓋掉這個死連結。
  rm -f ${PKG_BUILD}/resource/Cousine-Regular.ttf
  curl -sL -o ${PKG_BUILD}/resource/Cousine-Regular.ttf \
    https://raw.githubusercontent.com/ocornut/imgui/master/misc/fonts/Cousine-Regular.ttf
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  cp ${PKG_BUILD}/.${TARGET_NAME}/source/frontends/libretro/applewin_libretro.so ${INSTALL}/usr/lib/libretro/
}

# ===== w2xg2022: 预编译核心覆写(prebuilt-cores) =====
# NOTE(w2xg2022): 改用 w2xg2022/EmuELEC-prebuilt-cores 预编译的 applewin_libretro.so,不在主建置(尤其云端CI)
# 重新编译这个核心,省建置时间与磁盘。bash 后定义覆盖前面的同名函数。
# ⚠️ 工具链/glibc 变更后,须重跑该仓库的 build-cores workflow 重编,否则 ABI 不匹配。
# curl 用 -f:HTTP 错误(如404)直接失败,避免把错误页当成 .so 装进固件。
make_target() {
  : not
}

makeinstall_target() {
  mkdir -p ${INSTALL}/usr/lib/libretro
  curl -fsSL -o ${INSTALL}/usr/lib/libretro/applewin_libretro.so \
    https://github.com/w2xg2022/EmuELEC-prebuilt-cores/releases/latest/download/applewin_libretro.so || { echo "预编译核心下载失败: applewin_libretro.so"; exit 1; }
}
