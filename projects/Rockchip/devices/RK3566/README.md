# MD1000

MD1000 开发板（RK3566，Mali-G52）。

**Build**

* `PROJECT=Rockchip DEVICE=RK3566 ARCH=aarch64 make image`

  ★device 目录已从 `MD1000` 改名为 `RK3566`，编译要用 `DEVICE=RK3566`★
  （产出的映像仍带 `-MD1000` 机型后缀）。但**运行期**的 `EE_DEVICE` 取自 `/ee_arch`，
  那里**仍然是 `MD1000`** —— EmuELEC 脚本里做机型判断时两个名字都要列，
  只写 `RK3566` 会静默不命中（不报错、继续走错分支）。

## 与 RK356x device 的差异

| 项 | RK356x | MD1000 |
|---|---|---|
| 内核 | `rk356x-4.19`（firefly BSP，2022 年后停更） | `rk356x-6.6`（rockchip-linux develop-6.6，已含上游 stable 6.6.89） |
| Mali kbase | r16p0 | g25p0-00eac0 |
| dtb | firefly roc-pc | `rk3566-md1000.dtb` |
| 串口 | ttyFIQ0 | ttyS2 |
| 启动方式 | 自建 u-boot 刷进映像 | **链载（不构建 u-boot）** |

## 启动方式：链载（当前方案）

MD1000 出厂/现役的 u-boot 在 eMMC 上（Armbian 装的）。已知它**扫不到 USB 设备**，
所以 U 盘上的 EmuELEC 无法由它直接引导。解法是沿用 ROCKNIX 已验证过的 booti 链载：
**内核和 dtb 放 eMMC，rootfs（SYSTEM）留在 U 盘**——链载之后内核已是 Linux，
USB 由 Linux 完整驱动接管，绕开 u-boot 扫不到 USB 的限制。

因为 EmuELEC 和 ROCKNIX 同为 LibreELEC 血统，initramfs 都靠 cmdline 的
`boot=` / `disk=` 找设备，所以同一招直接适用，只需换标签。

### 一次性安装

1. U 盘 dd 写入 EmuELEC 完整映像（含分区表）。
2. 把 U 盘上的 `KERNEL` 和 `rk3566-md1000.dtb` 复制到 eMMC Armbian 的
   `/boot/emuelec/KERNEL` 和 `/boot/emuelec/rk3566-md1000.dtb`。
3. 备份并修改 Armbian 的 `/boot/boot.cmd`，在 `setenv load_addr` 那行**之前**插入下面的块。
4. 重编：`mkimage -C none -A arm -T script -n 'flatmax load script' -d /boot/boot.cmd /boot/boot.scr`
5. 默认无 TRIGGER = 开 Armbian（安全）。要进 EmuELEC 就 `touch /boot/emuelec/TRIGGER` 后重启。

```
setenv ee_kernel_addr "0x02080000"
setenv ee_fdt_addr "0x08300000"
if test -e ${devtype} ${devnum} emuelec/TRIGGER; then
	echo "=== EmuELEC chainload triggered ==="
	load ${devtype} ${devnum} ${ee_kernel_addr} emuelec/KERNEL
	load ${devtype} ${devnum} ${ee_fdt_addr} emuelec/rk3566-md1000.dtb
	setenv bootargs "boot=LABEL=EMUELEC disk=LABEL=STORAGE quiet console=ttyS2,1500000 console=tty0"
	booti ${ee_kernel_addr} - ${ee_fdt_addr}
	echo "=== EmuELEC booti failed, falling back to Armbian ==="
fi
```

标签取自 `distributions/EmuELEC/options`：`DISTRO_BOOTLABEL="EMUELEC"`、
`DISTRO_DISKLABEL="STORAGE"`；内核文件名取自 `config/options` 的 `KERNEL_NAME="KERNEL"`。

参考 `md1000-dualboot` 里 ROCKNIX 那套（同样机制，已实机验证）。

### 构建侧为什么不产生 u-boot

`options` 里 `UBOOT_SYSTEM="md1000"` 非空，因此 `scripts/image` 不会走
`DEVICE_BOARDS` 那条循环去 `install u-boot`；而 `bootloader/release` 和
`bootloader/mkimage` 里每个 u-boot 产物（idbloader/uboot/trust）都有 `-f` 保护，
产物不存在就跳过，映像照样能出。`KERNEL_TARGET="Image"`（非 uImage），
所以也不会因此拉进 `u-boot-tools:host`。

`scripts/uboot_helper` 里保留 MD1000 一项，仅为满足 `scripts/image` 启动时的
`UBOOT_SYSTEM` 校验，其 `config` 值在链载模式下不会被使用。

## dts：真档，不是 patch

`packages/linux/sources/rk3566-md1000.dts` 是真档，由 `packages/linux/package.mk`
的 `post_unpack()` 拷进内核树并幂等地补一行 `dtb-$(CONFIG_ARCH_ROCKCHIP)`。
不用 patch 的理由见该文件里的注释（云端 kernel 指纹只扫 `PKG_NAME="linux"` 的目录，
放 devices 层 patch 目录会被静默漏掉——2026-07-24 X98mini AV dtb 就栽在这里）。

源头是我们自己 mainline 6.18 树里的同名 dts，翻译成 vendor 方言时的对照：

| mainline | vendor 6.6 | 说明 |
|---|---|---|
| `&combphy1` / `&combphy2` | `&combphy1_usq` / `&combphy2_psq` | 纯改名 |
| `&usb2phy1_host` / `&usb2phy1_otg` | `&u2phy1_host` / `&u2phy1_otg` | phy0 两边同名，phy1 不同 |
| `&usb_host0_xhci` / `&usb_host1_xhci` | `&usbdrd_dwc3` / `&usbhost_dwc3` | 还要另开父节点 `&usbdrd30` / `&usbhost30` |
| `&spdif` / `&vpu` | `&spdif_8ch` / `&vdpu` | 纯改名 |
| `hdmi-connector` + `&hdmi_in`/`&hdmi_out` + `&vp0` | `&hdmi_in_vp0` + `&route_hdmi` | vendor 在 rk356x.dtsi 里已接好 vp0↔hdmi，只是默认 disabled |
| codec = `sound-dai = <&rk809>` | PMIC 下 `rk809_codec: codec` 子节点 | **强制**：`rk817_codec.c` 是 `of_get_child_by_name(parent, "codec")` |
| `simple-audio-card` | `rockchip,multicodecs-card` | 配合上一行 |
| WiFi/BT | **保持 mainline 写法** | vendor 的 rockchip_wlan 只有 rkwifi(Broadcom)，没有 RTL8822CS；上游 rtw88 有 |

已验证：`make ARCH=arm64 rockchip/rk3566-md1000.dtb` 零错误零告警，反编译核对过
gpu/hdmi/eMMC/SD/gmac/uart2/i2s0/i2s1/sdmmc1 的 status 与 codec、声卡、wifi、bluetooth 节点。

**注意**：6.6 树里混着两种 dts——随上游 stable 合并进来的 mainline 风格档
（`rk3566-box-demo.dts`、`rk3568-evb1-v10.dts` 等）**不在 Makefile 里、根本不编**，
实测直接编会报 9 个 label not found。找 vendor 写法的范例要认准有没有进 Makefile，
真正能编的是 `rk3566-box.dtsi` / `rk3566-box-demo-v10.dtsi` 那一支。

## 待办

1. **AV（3.5mm）音频未解**：其余外设已实机验证可用（HDMI 有声、网口、蓝牙、手柄）。
   AV 口播放时是「沙沙」声。已经排查到的（★别再重查★，详见 memory `md1000_emuelec_av_audio`）：
   - 数位链**全部正确**：DMA 连续零 XRUN、I2S 寄存器与 Armbian 逐字节相同、
     codec slave+16bit、MCLK 12.288MHz、pinmux 正确、HP 路径寄存器与驱动预期一致。
   - **PMIC+codec 全 255 颗寄存器（0x00~0xfe）比对，设定完全相同**
     （差异只有 RTC 时间、ADC 取样率、电量计等动态值）。
   - codec 驱动 **mainline 与 vendor 两版都沙沙** → 驱动选择不是原因。
   - ★手机录音频谱证实「沙沙」**不是白噪音**★：91.4% 能量在 300Hz 以下、
     主峰 59Hz（市电哼声特征）、440Hz 讯号只占 2.1%、高频几乎是空的
     → 数位链本来就没问题，噪声是**类比端**混进来的。
   - 待补：Armbian 同条件录音当对照。若它也有 59Hz，则噪声根本不是板子发出来的。
   - ★比对寄存器前必须 `echo 1 > /sys/kernel/debug/regmap/0-0020/cache_bypass`★，
     否则 regmap 快取会给出假数据（曾据此误判「位宽 24bit」「codec 当 master」）。
2. **kernel config 可再瘦身**：`linux/rk356x-6.6/linux.aarch64.conf` 由
   `rockchip_linux_defconfig` + `rk3566.config` 展开，已确认
   `CONFIG_MALI_BIFROST=y`、`CONFIG_DRM_PANFROST` 未开、`CONFIG_RTW88_8822CS=m`；
   但仍带着 `CONFIG_MALI400`/`CONFIG_MALI_MIDGARD` 等 MD1000 用不到的项。
3. ~~**Vulkan 尚未打开**~~ **（已完成）**：device 层 `options` 已设 `VULKAN="vulkan-loader"`
   （Rockchip **project 层**那个 `VULKAN="no"` 是预设值，会被 device 层覆盖，★别被它误导★）。
   GLES 用户空间已从 r16p0 换成 **g24p0**（`packages/graphics/libmali`），
   Vulkan 另有**独立 blob** `libmali.so.1.9.0`（`packages/graphics/libmali-vulkan`，
   不在 GLES 那套仓库里），并在 `ADDITIONAL_PACKAGES` 显式带进映像。
   内核侧 kbase 是 6.6 树内的 `CONFIG_MALI_BIFROST=y`（g25p0）。
   ★注意:Mali 的 user-space blob 必须与内核 kbase 版本相容★ ——
   所以**换内核大版本（例如退回 5.10）很可能等于放弃 Vulkan**，
   届时要重做一轮 blob 配对验证，愈旧的 blob 愈可能只有 GLES。
4. **自建 u-boot（可选，出货形态）**：若要做成 RKDevTool 直刷 eMMC 冷启动的完整映像，
   需要验证 firefly u-boot 的 DDR 初始化参数与 rkbin blob 是否适配 MD1000。未验证。
