# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="linux"
PKG_LICENSE="GPL"
PKG_SITE="http://www.kernel.org"
PKG_DEPENDS_HOST="ccache:host rsync:host openssl:host"
PKG_DEPENDS_TARGET="toolchain linux:host kmod:host xz:host keyutils ${KERNEL_EXTRA_DEPENDS_TARGET}"
PKG_NEED_UNPACK="${LINUX_DEPENDS} $(get_pkg_directory initramfs) $(get_pkg_variable initramfs PKG_NEED_UNPACK)"
PKG_LONGDESC="This package contains a precompiled kernel image and the modules."
PKG_IS_KERNEL_PKG="yes"
PKG_STAMP="${KERNEL_TARGET} ${KERNEL_MAKE_EXTRACMD}"

PKG_PATCH_DIRS="${LINUX}"

case "$LINUX" in
  md1000-6.18)
    # ★2026-07-31:AV(3.5mm)沙沙声 —— 改用 mainline 6.18(我们自己的 armbian-kernel fork)★
    #
    # 为什么换内核(见 memory: md1000_emuelec_av_audio 的三方比对):
    #   Armbian(6.18 mainline) ✅ AV 有声 / ROCKNIX(7.0.2 mainline) ✅ 有声 / 我们(6.6 vendor BSP) ❌
    #   codec/声卡/binding/TRCM 全都换成与能出声的系统一致后,症状从「沙沙」变「无声」,
    #   ★唯一从没换过的元件 = 6.6 vendor 的 i2s 控制器驱动(rockchip_i2s_tdm.c,3582 行
    #   vs mainline 1445 行)★,换内核就是要把这最后一个变数也换掉。
    #
    # 为什么选 6.18 而不是 ROCKNIX 的 7.0.2:
    #   ★这棵树是我们自己的 fork,MD1000 板级支援 + AV 的 dts 已经在里面而且实机验证过★
    #   (arch/arm64/boot/dts/rockchip/rk3566-md1000.dts 含完整 AV:simple-audio-card /
    #   rk809 codec DAI 挂 pmic 本体 / vcc_amp 功放 / TRCM / i2s1m0_mclk)。
    #   走 7.0.2 这些要从 ROCKNIX 重新移植一遍。
    #
    # ★Vulkan 不受影响(已实测)★:kbase 是外挂模组(rocknix/mali_kbase),对 6.18.40 编译
    #   产出 mali_kbase.ko 零错误(源码里有 6.11/6.12/6.17/7.0 的版本分支)。
    #   但 6.18 mainline 树内【没有】kbase(Armbian 用 Panfrost),所以要另外加模组包 —— 见 TODO。
    #
    # 来源:w2xg2022/armbian-kernel 分支 6.18(HEAD d77140b4)的 GitHub archive。
    #
    # ★换 commit 的正确做法(2026-08-02 更正)★
    #   直接改 PKG_VERSION,然后【下载 GitHub 产生的 archive】取它的 sha256:
    #     curl -sL https://github.com/w2xg2022/armbian-kernel/archive/<sha>.tar.gz | sha256sum
    #   ☠️ 不要用本地 git archive --prefix=... 重打包再算 sha256 ☠️
    #   本地重打包的顶层目录名(linux-<sha>/)与 GitHub 的(armbian-kernel-<sha>/)不同,
    #   内容一模一样但 sha256 不同 —— VM 上因为 sources/ 命中快取而毫无症状,
    #   一上云端就是 checksum 不符;更坑的是失败讯息显示的是【后续镜像的 404】,
    #   看起来像「commit 不见了」,实际 commit 好端端在、archive 也回 200。
    #   (2026-08-02 云编译第二轮就栽在这,查了半天才看到 checksum 那行 WARNING。)
    PKG_VERSION="d77140b4732ad52793dba8b97a5b0c79a1e20f86"
    # NOTE(w2xg2022): 2026-08-02 修正 —— 旧值是拿【本地重打包过的 tarball】算的,
    # 云端永远算不出来。实证:GitHub 产生的 archive 顶层目录是 armbian-kernel-<sha>/,
    # VM sources/ 里那颗是 linux-<sha>/(被改名重打包),内容 98000 项逐项相同、
    # 只有目录名不同,所以 sha256 不同。云端下载 245MB 两次都成功却 checksum 不符,
    # 接着去试 LibreELEC 镜像(没有)才吐 404 —— ★错误讯息说的 404 是误导,
    # 真因是 checksum★。现值取自 github archive,连抓两次一致。
    PKG_SHA256="7c8ac8b27621402e07ccc0c59c033ca4614dedfa20d01e337ca0ca695aaf1893"
    PKG_URL="https://github.com/w2xg2022/armbian-kernel/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    # 这棵树没有我们自维护的 6.6 patch(maxio PHY 等上游已有/已合并),不套 patch 目录
    PKG_PATCH_DIRS=""
    ;;
  rk356x-6.6)
    # rockchip-linux/kernel develop-6.6 @ 2025-08-08(已合并上游 stable v6.6.89)
    # Mali kbase: g25p0-00eac0(bifrost/valhall 均在树内)
    # 为什么选 6.6 而不是 5.10/6.1，见 devices/MD1000/README.md
    PKG_VERSION="1ba51b059f25533c5529b7f68186190b47d6a7b3"
    PKG_SHA256="cb0fcfcbaabf30c5a37f70a7452a3d8c5565cb3a852ffc417005a49d96bea8ed"
    PKG_URL="https://github.com/rockchip-linux/kernel/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    ;;
  rockchip-4.4)
    PKG_VERSION="aa8bacf821e5c8ae6dd8cae8d64011c741659945"
    PKG_SHA256="a2760fe89a15aa7be142fd25fb08ebd357c5d855c41f1612cf47c6e89de39bb3"
    PKG_URL="https://github.com/rockchip-linux/kernel/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    ;;
  rk356x-4.19)
    PKG_VERSION="c0c173e0214eeaa0d057599d2f1c6a83213483b1"
    PKG_SHA256="d748bc0f272373ed219a9bfd242566871dafd0437f88d0212780b8469ea89e5e"
    PKG_URL="https://gitlab.com/firefly-linux/kernel/-/archive/$PKG_VERSION/kernel-$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="RK356x"
    ;;
  OdroidM1-4.19)
    PKG_VERSION="e45b118834e1395eeacbed77e8b8f35e8105663e"
    PKG_SHA256="3c4f1bea0b8c26d9951c8b46c6c93127fc0929ff9947c5eb8e479fbaf05fa1f4"
    PKG_URL="https://github.com/hardkernel/linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="RK356x"
    ;;
  odroid-go-a-4.4)
    PKG_VERSION="faeb665a41b53ebb386e69fe737ccf0707aaf07b"
    PKG_SHA256="bef15386f296b282e1e75ed78f14c7c0762058806da37854d09af642a15594ae"
    PKG_URL="https://github.com/hardkernel/linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="OdroidGoAdvance base"
    ;;
  gameforce-4.4)
    PKG_VERSION="8eddb294dcb1a1b0cf63bdf04ea5cdc41a9bd601"
    PKG_SHA256="ad2f6fee44dfb19c8a43722ca02601f6742af39129f0c79c990ed582709f63cf"
    PKG_URL="https://github.com/shantigilbert/hardkernel-linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="GameForce base"
    ;;
  raspberrypi)
    PKG_VERSION="3c235dcfe80a7c7ba360219e4a3ecb256f294376" # 4.19.83
    PKG_SHA256="23a222d8864107b296b3bf580106421899964af879bb7f1c440e875e565fd6f3"
    PKG_URL="https://github.com/raspberrypi/linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    ;;
  *)
    PKG_VERSION="5.1.16"
    PKG_SHA256="8a3e55be3e788700836db6f75875b4d3b824a581d1eacfc2fcd29ed4e727ba3e"
    PKG_URL="https://www.kernel.org/pub/linux/kernel/v5.x/$PKG_NAME-$PKG_VERSION.tar.xz"
    PKG_PATCH_DIRS="default"
    ;;
esac

PKG_KERNEL_CFG_FILE=$(kernel_config_path) || die

if [ -n "${KERNEL_TOOLCHAIN}" ]; then
  PKG_DEPENDS_HOST+=" gcc-${KERNEL_TOOLCHAIN}:host"
  PKG_DEPENDS_TARGET+=" gcc-${KERNEL_TOOLCHAIN}:host"
  HEADERS_ARCH=${TARGET_ARCH}
fi

# NOTE(w2xg2022): 6.6 的 tools/perf 需要外部 libtraceevent(旧内核是内建的),
# 缺了会直接 "ERROR: libtraceevent is missing … or build with NO_LIBTRACEEVENT=1"。
# 我们不打包 libtraceevent,所以下面 make perf 时带上 NO_LIBTRACEEVENT=1
# (这是错误信息本身给出的官方开关,代价是 perf 少掉 tracepoint 解析功能)。
if [ "${PKG_BUILD_PERF}" != "no" ] && grep -q ^CONFIG_PERF_EVENTS= ${PKG_KERNEL_CFG_FILE}; then
  PKG_BUILD_PERF="yes"
  PKG_DEPENDS_TARGET+=" binutils elfutils libunwind zlib openssl"
fi

if [ "${TARGET_ARCH}" = "x86_64" ]; then
  PKG_DEPENDS_TARGET+=" elfutils:host pciutils"
  PKG_DEPENDS_UNPACK+=" intel-ucode kernel-firmware"
elif [ "${TARGET_ARCH}" = "arm" -a "${DEVICE}" = "iMX6" ]; then
  PKG_DEPENDS_UNPACK+=" firmware-imx"
fi

if [[ "${KERNEL_TARGET}" = uImage* ]]; then
  PKG_DEPENDS_TARGET+=" u-boot-tools:host"
fi

# Ensure that the dependencies of initramfs:target are built correctly, but
# we don't want to add initramfs:target as a direct dependency as we install
# this "manually" from within linux:target
for pkg in $(get_pkg_variable initramfs PKG_DEPENDS_TARGET); do
  ! listcontains "${PKG_DEPENDS_TARGET}" "${pkg}" && PKG_DEPENDS_TARGET+=" ${pkg}" || true
done

post_patch() {
  # linux was already built and its build dir autoremoved - prepare it again for kernel packages
  if [ -d ${PKG_INSTALL}/.image ]; then
    cp -p ${PKG_INSTALL}/.image/.config ${PKG_BUILD}
    kernel_make -C ${PKG_BUILD} prepare

    # restore the required Module.symvers from an earlier build
    cp -p ${PKG_INSTALL}/.image/Module.symvers ${PKG_BUILD}
  fi
}

post_unpack() {
  # NOTE(w2xg2022): 只有内核树里没有 exFAT 时才注入外挂的 exfat-linux。
  # 树内已经有(6.6 起是标配)就必须跳过 —— 上游这段会先 rm -rf 掉 fs/exfat 再解开
  # 那份老驱动,而它还在用 bd_part / hd_struct / i_ctime / .iterate 这些 5.x 就已经
  # 删掉的 API,一旦 CONFIG_EXFAT_FS=y 就是几十条编译错误(2026-07-28 实测)。
  # 换句话说:注入 = 把树内的新 exFAT 换成一份编不过的老 exFAT。
  if [ -f "${PKG_BUILD}/fs/exfat/Kconfig" ]; then
    echo "post_unpack: kernel has in-tree exFAT, skipping exfat-linux injection"
  else
    # Add exFAT
    ${SCRIPTS}/get exfat-linux
    local PKG_BUILD_EXFAT="${PKG_BUILD}/fs/exfat"
    [ -e "$PKG_BUILD_EXFAT" ] && rm -rf "$PKG_BUILD_EXFAT"
    mkdir -p "$PKG_BUILD_EXFAT"
    tar --strip-components=1 -xf "${SOURCES}/exfat-linux/exfat-linux-$(get_pkg_version exfat-linux).tar.gz" -C "$PKG_BUILD_EXFAT"
    sed -i '/source "fs\/fat\/Kconfig"/a source "fs\/exfat\/Kconfig"' "${PKG_BUILD}/fs/Kconfig"
    sed -i '/obj-$(CONFIG_FAT_FS).*+= fat\//a obj-$(CONFIG_EXFAT_FS)\t\t+= exfat\/' "${PKG_BUILD}/fs/Makefile"
  fi

  # NOTE(w2xg2022): 注入本 fork 自维护的机型专属 dts —— ★真档,不用 patch★。
  # 与 Amlogic-no 同一套做法(见 projects/Amlogic-ce/devices/Amlogic-no/packages/linux/package.mk):
  # dts 放在本 package 的 sources/ 下,而本 package 目录(PKG_NAME=linux)本来就在 kernel bundle
  # 指纹的扫描范围内,所以 dts 一改云端指纹就变、自动重编 —— 不会像放在 devices 层 patch 目录
  # 那样因不在指纹范围而被云端静默漏掉(2026-07-24 X98mini AV dtb 就是这样没进云端固件的)。
  # 每个 sources/*.dts 拷进 rockchip dts 目录并补上 dtb-y 一行(幂等)。
  #
  # ★只对 6.6 vendor 树做★:sources/ 下那份 dts 是【为 vendor 树写的】。
  # md1000-6.18 那棵树(我们自己的 armbian-kernel fork)【本来就带 MD1000 dts】,
  # 而且那份是 Armbian 实机验证过 AV 能出声的版本 —— 盖上去只会把验证过的换成没验证过的。
  if [ "${LINUX}" = "rk356x-6.6" ]; then
    local _dtsdir="${PKG_BUILD}/arch/${TARGET_KERNEL_ARCH:-arm64}/boot/dts/rockchip"
    local _dts _name
    for _dts in ${PKG_DIR}/sources/*.dts; do
      [ -f "${_dts}" ] || continue
      cp -v "${_dts}" "${_dtsdir}/"
      _name="$(basename "${_dts}" .dts)"
      grep -q "${_name}.dtb" "${_dtsdir}/Makefile" || \
        echo "dtb-\$(CONFIG_ARCH_ROCKCHIP) += ${_name}.dtb" >> "${_dtsdir}/Makefile"
    done
  else
    echo "post_unpack: LINUX=${LINUX} 使用内核树自带的 dts(不注入 sources/*.dts)"
    # 自检:树里必须真的有 MD1000 的 dts,否则后面 make dtbs 会静默少一个档
    [ -f "${PKG_BUILD}/arch/${TARGET_KERNEL_ARCH:-arm64}/boot/dts/rockchip/rk3566-md1000.dts" ] || \
      { echo "post_unpack: ERROR 内核树里没有 rk3566-md1000.dts"; exit 1; }
  fi

  # ── AV(3.5mm)没声音的真因(I2S mclkout 的 mux reparent 静默失败)已改在 dts ──
  # 这里【曾经】用 sed 把 clk-rk3568.c 里 7 行 PNAME(i2s?_mclkout*) 的 parent 名
  # 从 "mclk_*" 回移成上游 6.18 的 "clk_*",让 dts 的 CLK_I2S1_8CH_TX 请求成立。
  # 现改成更小的做法:dts 直接指 vendor 本来就要你指的 MCLK_I2S1_8CH_TX,
  # 内核 C 档一行不动(详见 sources/rk3566-md1000.dts 里 pmic@20 的注释)。
  # ★两者不能并存★:sed 一旦把候选改成 clk_*,dts 指的 mclk_i2s1_8ch_tx 就又不在
  # 候选名单里,同一个 bug 会原样复发。所以 sed 已整段移除,别再加回来。

  # ────────────────────────────────────────────────────────────────────────
  # ★下面整段【只对 6.6 vendor 树】有意义★:它是把 mainline 的 codec 驱动与 binding
  # 移植进 vendor 树。md1000-6.18 那棵树本来就是 mainline,驱动与 MFD cell 都已经是对的,
  # 再套一次只会把好的覆盖掉(而且 sed 命中数会 =0 直接 exit 1)。
  if [ "${LINUX}" != "rk356x-6.6" ]; then
    echo "post_unpack: LINUX=${LINUX} 已是 mainline,跳过 codec 移植"
    return 0
  fi

  # ★2026-07-31:AV(3.5mm)沙沙声 —— 整组改用 mainline 音频链(照 ROCKNIX 配方)★
  #
  # 三方比对的结论(见 memory: md1000_emuelec_av_audio):
  #   Armbian(mainline) ✅ 有声 / ROCKNIX(mainline) ✅ 有声 / 我们(vendor BSP) ❌ 沙沙
  # 两个【实机确认能出声】的系统用的是【同一套配方】:
  #   simple-audio-card + mainline rk817_codec + DAI 挂 pmic 本体 + TRCM 保留
  # 而我们这份 dts 本来就是从 ROCKNIX 那份改过来的(注释都是同一段英文的中译),
  # 是我们单方面分岔成 vendor 配方。这里把驱动侧也改回去。
  #
  # ① 用 mainline 的 rk817_codec.c 整档取代 BSP 那份(1642 行 vendor 版)
  #    ★真档取代,不用 patch★(依约定见 memory: feedback_emuelec_real_files_not_patches)
  #    相容性已逐项查过:mainline 用到的【所有】暂存器巨集 6.6 的 include/linux/mfd/rk808.h
  #    都有;唯一 API 差异是 platform_driver 的 void 版 remove 在 6.6 叫 remove_new
  #    (6.11+ 才改名回 .remove),已在 sources/rk817_codec.c 里改好并注明。
  #    ★CONFIG_SND_SOC_RK817=y 本来就开着,同一个 config 符号编的就是这个档,不必改 config★
  if [ -f "${PKG_DIR}/sources/rk817_codec.c" ]; then
    cp -v "${PKG_DIR}/sources/rk817_codec.c" "${PKG_BUILD}/sound/soc/codecs/rk817_codec.c"
  else
    echo "post_unpack: ERROR sources/rk817_codec.c missing"; exit 1
  fi

  # ② MFD cell 去掉 .of_compatible
  #    BSP 的 drivers/mfd/rk808.c 写:
  #        { .name = "rk817-codec", .of_compatible = "rockchip,rk817-codec", }
  #    它要求 pmic 底下有个 compatible 相符的 codec 子节点(vendor binding)。
  #    mainline binding 没有 codec 子节点(DAI 直接挂 pmic 本体),留着 of_compatible
  #    会让这个 cell 找不到节点。mainline 的 rk8xx-core.c 就是写 { .name = "rk817-codec", }。
  #    ★能这样做的根据★:codec 平台装置没有 of_node 时,ASoC 会退回用 parent 的 of_node
  #        soc-core.c: if (!of_node && component->dev->parent)
  #                        of_node = component->dev->parent->of_node;
  #    (6.6 与 6.18 都有这段),所以 dts 的 sound-dai = <&rk809> 仍然解析得到。
  #    ★命中数必须 = 1,否则 exit 1★ —— 静默失败正是这类 bug 的形态,不能让修法也静默失败。
  local _n
  _n=$(grep -c '\.of_compatible = "rockchip,rk817-codec"' "${PKG_BUILD}/drivers/mfd/rk808.c" || true)
  if [ "${_n}" != "1" ]; then
    echo "post_unpack: ERROR rk817-codec of_compatible hits=${_n} (expected 1)"; exit 1
  fi
  sed -i 's/{ .name = "rk817-codec", .of_compatible = "rockchip,rk817-codec", }/{ .name = "rk817-codec", }/' \
    "${PKG_BUILD}/drivers/mfd/rk808.c"
  grep -q '{ .name = "rk817-codec", }' "${PKG_BUILD}/drivers/mfd/rk808.c" || \
    { echo "post_unpack: ERROR rk817-codec cell sed did not apply"; exit 1; }
}

make_host() {
  :
}

makeinstall_host() {
  make \
    ARCH=${HEADERS_ARCH:-${TARGET_KERNEL_ARCH}} \
    HOSTCC="${TOOLCHAIN}/bin/host-gcc" \
    HOSTCXX="${TOOLCHAIN}/bin/host-g++" \
    HOSTCFLAGS="${HOST_CFLAGS}" \
    HOSTCXXFLAGS="${HOST_CXXFLAGS}" \
    HOSTLDFLAGS="${HOST_LDFLAGS}" \
    INSTALL_HDR_PATH=dest \
    headers_install
  mkdir -p ${SYSROOT_PREFIX}/usr/include
    cp -R dest/include/* ${SYSROOT_PREFIX}/usr/include
}

pre_make_target() {
  ( cd ${ROOT}
    rm -rf ${BUILD}/initramfs
    rm -f ${STAMPS_INSTALL}/initramfs/install_target ${STAMPS_INSTALL}/*/install_init
    ${SCRIPTS}/install initramfs
  )
  pkg_lock_status "ACTIVE" "linux:target" "build"

  cp ${PKG_KERNEL_CFG_FILE} ${PKG_BUILD}/.config

  # set initramfs source
  ${PKG_BUILD}/scripts/config --set-str CONFIG_INITRAMFS_SOURCE "$(kernel_initramfs_confs) ${BUILD}/initramfs"

  # set default hostname based on ${DISTRONAME}
  ${PKG_BUILD}/scripts/config --set-str CONFIG_DEFAULT_HOSTNAME "${DISTRONAME}"

  # disable swap support if not enabled
  if [ ! "${SWAP_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_SWAP
  fi

  # disable nfs support if not enabled
  if [ ! "${NFS_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_NFS_FS
  fi

  # disable cifs support if not enabled
  if [ ! "${SAMBA_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_CIFS
  fi

  # disable iscsi support if not enabled
  if [ ! "${ISCSI_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_SCSI_ISCSI_ATTRS
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_TCP
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_BOOT_SYSFS
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_IBFT_FIND
    ${PKG_BUILD}/scripts/config --disable CONFIG_ISCSI_IBFT
  fi

  # disable lima/panfrost if libmali is configured
  if [ "${OPENGLES}" = "libmali" ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_DRM_LIMA
    ${PKG_BUILD}/scripts/config --disable CONFIG_DRM_PANFROST
  fi

  # disable wireguard support if not enabled
  if [ ! "${WIREGUARD_SUPPORT}" = yes ]; then
    ${PKG_BUILD}/scripts/config --disable CONFIG_WIREGUARD
  fi

  if [ "${TARGET_ARCH}" = "x86_64" ]; then
    # copy some extra firmware to linux tree
    mkdir -p ${PKG_BUILD}/external-firmware
      cp -a $(get_build_dir kernel-firmware)/.copied-firmware/{amdgpu,amd-ucode,i915,radeon,e100,rtl_nic} ${PKG_BUILD}/external-firmware

    cp -a $(get_build_dir intel-ucode)/intel-ucode ${PKG_BUILD}/external-firmware

    FW_LIST="$(find ${PKG_BUILD}/external-firmware \( -type f -o -type l \) \( -iname '*.bin' -o -iname '*.fw' -o -path '*/intel-ucode/*' \) | sed 's|.*external-firmware/||' | sort | xargs)"

    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE "${FW_LIST}"
    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE_DIR "external-firmware"

  elif [ "${TARGET_ARCH}" = "arm" -a "${DEVICE}" = "iMX6" ]; then
    mkdir -p ${PKG_BUILD}/external-firmware/imx/sdma
      cp -a $(get_build_dir firmware-imx)/firmware/sdma/*imx6*.bin ${PKG_BUILD}/external-firmware/imx/sdma
      cp -a $(get_build_dir firmware-imx)/firmware/vpu/*imx6*.bin ${PKG_BUILD}/external-firmware

    FW_LIST="$(find ${PKG_BUILD}/external-firmware -type f | sed 's|.*external-firmware/||' | sort | xargs)"

    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE "${FW_LIST}"
    ${PKG_BUILD}/scripts/config --set-str CONFIG_EXTRA_FIRMWARE_DIR "external-firmware"
  fi
  
  kernel_make oldconfig

  if [ -f "${DISTRO_DIR}/${DISTRO}/kernel_options" ]; then
    while read OPTION; do
      [ -z "${OPTION}" -o -n "$(echo "${OPTION}" | grep '^#')" ] && continue

      if [ "${OPTION##*=}" == "n" -a "$(${PKG_BUILD}/scripts/config --state ${OPTION%%=*})" == "undef" ]; then
        continue
      fi

      if [ "$(${PKG_BUILD}/scripts/config --state ${OPTION%%=*})" != "$(echo ${OPTION##*=} | tr -d '"')" ]; then
        MISSING_KERNEL_OPTIONS+="\t${OPTION}\n"
      fi
    done < ${DISTRO_DIR}/${DISTRO}/kernel_options

    if [ -n "${MISSING_KERNEL_OPTIONS}" ]; then
      print_color CLR_WARNING "LINUX: kernel options not correct: \n${MISSING_KERNEL_OPTIONS%%}\nPlease run ./tools/check_kernel_config\n"
    fi
  fi
}

make_target() {

export KCFLAGS="-Wno-deprecated-declarations -Wno-stringop-overflow -Wno-array-bounds -Wno-misleading-indentation -Wno-array-compare -Wno-address -Wno-dangling-pointer -Wno-stringop-overread"

  # arm64 target does not support creating uImage.
  # Build Image first, then wrap it using u-boot's mkimage.
  if [[ "${TARGET_KERNEL_ARCH}" = "arm64" && "${KERNEL_TARGET}" = uImage* ]]; then
    if [ -z "${KERNEL_UIMAGE_LOADADDR}" -o -z "${KERNEL_UIMAGE_ENTRYADDR}" ]; then
      die "ERROR: KERNEL_UIMAGE_LOADADDR and KERNEL_UIMAGE_ENTRYADDR have to be set to build uImage - aborting"
    fi
    KERNEL_UIMAGE_TARGET="${KERNEL_TARGET}"
    KERNEL_TARGET="${KERNEL_TARGET/uImage/Image}"
  fi

  DTC_FLAGS=-@ kernel_make ${KERNEL_TARGET} ${KERNEL_MAKE_EXTRACMD} modules

  if [ "${PKG_BUILD_PERF}" = "yes" ]; then
    ( cd tools/perf

      # arch specific perf build args
      case "${TARGET_ARCH}" in
        x86_64)
          PERF_BUILD_ARGS="ARCH=x86"
          ;;
        aarch64)
          PERF_BUILD_ARGS="ARCH=arm64"
          ;;
        *)
          PERF_BUILD_ARGS="ARCH=${TARGET_ARCH}"
          ;;
      esac

      WERROR=0 \
      NO_LIBPERL=1 \
      NO_LIBPYTHON=1 \
      NO_SLANG=1 \
      NO_GTK2=1 \
      NO_LIBNUMA=1 \
      NO_LIBAUDIT=1 \
      NO_LZMA=1 \
      NO_SDT=1 \
      NO_LIBTRACEEVENT=1 \
      CROSS_COMPILE="${TARGET_PREFIX}" \
      JOBS="${CONCURRENCY_MAKE_LEVEL}" \
        make ${PERF_BUILD_ARGS}
      mkdir -p ${INSTALL}/usr/bin
        cp perf ${INSTALL}/usr/bin
    )
  fi

  if [ -n "${KERNEL_UIMAGE_TARGET}" ]; then
    # determine compression used for kernel image
    KERNEL_UIMAGE_COMP=${KERNEL_UIMAGE_TARGET:7}
    KERNEL_UIMAGE_COMP=$(echo ${KERNEL_UIMAGE_COMP:-none} | sed 's/gz/gzip/; s/bz2/bzip2/')

    # calculate new load address to make kernel Image unpack to memory area after compressed image
    if [ "${KERNEL_UIMAGE_COMP}" != "none" ]; then
      COMPRESSED_SIZE=$(stat -t "arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_TARGET}" | awk '{print $2}')
      # align to 1 MiB
      COMPRESSED_SIZE=$(( ((${COMPRESSED_SIZE} - 1 >> 20) + 1) << 20 ))
      PKG_KERNEL_UIMAGE_LOADADDR=$(printf '%X' "$(( ${KERNEL_UIMAGE_LOADADDR} + ${COMPRESSED_SIZE} ))")
      PKG_KERNEL_UIMAGE_ENTRYADDR=$(printf '%X' "$(( ${KERNEL_UIMAGE_ENTRYADDR} + ${COMPRESSED_SIZE} ))")
    else
      PKG_KERNEL_UIMAGE_LOADADDR=${KERNEL_UIMAGE_LOADADDR}
      PKG_KERNEL_UIMAGE_ENTRYADDR=${KERNEL_UIMAGE_ENTRYADDR}
    fi

    mkimage -A ${TARGET_KERNEL_ARCH} \
            -O linux \
            -T kernel \
            -C ${KERNEL_UIMAGE_COMP} \
            -a ${PKG_KERNEL_UIMAGE_LOADADDR} \
            -e ${PKG_KERNEL_UIMAGE_ENTRYADDR} \
            -d arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_TARGET} \
               arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_UIMAGE_TARGET}

    KERNEL_TARGET="${KERNEL_UIMAGE_TARGET}"
  fi
}

makeinstall_target() {
  mkdir -p ${INSTALL}/.image
  cp -p arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_TARGET} System.map .config Module.symvers ${INSTALL}/.image/

  kernel_make INSTALL_MOD_PATH=${INSTALL}/$(get_kernel_overlay_dir) modules_install
  rm -f ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/*/build
  rm -f ${INSTALL}/$(get_kernel_overlay_dir)/lib/modules/*/source

  if [ "${BOOTLOADER}" = "u-boot" ]; then
    mkdir -p ${INSTALL}/usr/share/bootloader
    for dtb in arch/${TARGET_KERNEL_ARCH}/boot/dts/*.dtb arch/${TARGET_KERNEL_ARCH}/boot/dts/*/*.dtb; do
      if [ -f ${dtb} ]; then
        cp -v ${dtb} ${INSTALL}/usr/share/bootloader
      fi
    done
  elif [ "${BOOTLOADER}" = "bcm2835-bootloader" ]; then
    mkdir -p ${INSTALL}/usr/share/bootloader/overlays

    # install platform dtbs, but remove upstream kernel dtbs (i.e. without downstream
    # drivers and decent USB support) as these are not required by LibreELEC
    for dtb in arch/${TARGET_KERNEL_ARCH}/boot/dts/*.dtb arch/${TARGET_KERNEL_ARCH}/boot/dts/*/*.dtb; do
      if [ -f ${dtb} ]; then
        cp -v ${dtb} ${INSTALL}/usr/share/bootloader
      fi
    done
    rm -f ${INSTALL}/usr/share/bootloader/bcm283*.dtb
    # duplicated in overlays below
    safe_remove ${INSTALL}/usr/share/bootloader/overlay_map.dtb

    # install overlay dtbs
    for dtb in arch/arm/boot/dts/overlays/*.dtb \
               arch/arm/boot/dts/overlays/*.dtbo; do
      cp ${dtb} ${INSTALL}/usr/share/bootloader/overlays 2>/dev/null || :
    done
    cp -p arch/${TARGET_KERNEL_ARCH}/boot/dts/overlays/README ${INSTALL}/usr/share/bootloader/overlays
  fi
}
