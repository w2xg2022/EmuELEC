# EmuELEC w2xg2022 Edition

本仓库基于上游 [EmuELEC](https://github.com/EmuELEC/EmuELEC) 二次开发，为适配的电视盒子/开发板等 ARM 设备提供云编译固件。

## 选型策略：四级志愿（驱动栈 × 图形 API）

给电视盒子/开发板适配怀旧游戏，模拟器能跑到什么天花板（尤其 PSP/PPSSPP），几乎完全由 **GPU 驱动栈 + 图形 API** 决定，不是调参能补的。按能力从高到低排四档：

1. 🥇 **原厂闭源 BSP 驱动（libmali）+ Vulkan** —— 最优
2. 🥈 **社区开源驱动（Mesa / Panfrost）+ Vulkan（PanVK）**
3. 🥉 **原厂闭源 BSP 驱动（libmali）+ OpenGL ES**
4. 🏅 **社区开源驱动（Mesa / Panfrost / Lima）+ OpenGL ES** —— 最底

> **为什么 Vulkan 这么关键**：同一颗 Mali、同一个 libmali blob，只把后端从 GLES 换成 Vulkan——轻量 2D 几乎无差（但更少顿挫/爆音）；中量 3D 快约 1.3 到 1.8 倍；重量 3D 快 1.5 到 2 倍以上，很多 GLES 跑不动的到 Vulkan 才可玩。弱 A55 CPU 受益最大（Vulkan 砍驱动开销、显式 render pass 契合 Mali tile 架构、减少 shader 即时编译顿卡）。PPSSPP 官方本就把 Vulkan 当 Mali 首选后端，所以 PSP 是 Vulkan 优势被放大的特例。

### 前提：GPU 世代决定志愿上限

芯片的 GPU 决定你最多能爬到第几志愿，硬件不支持就到顶：

| GPU（架构） | 代表芯片 | 志愿上限 | PSP |
|---|---|---|---|
| Mali-450（Utgard，仅 GLES2，无 Vulkan 硬件；开源驱动为 Lima） | RK3318 / RK3328 / RK3228H / RK3528 | 第四 | 基本无缘（定位 PS1/街机/N64-lite 以下） |
| Mali-G31（Bifrost，GLES3.2） | S905X2 / **S905W2** / S905L3A / S905X3 / H618 | 实务第三（G31 的 Vulkan 落地不成熟） | 轻到中量可玩 |
| Mali-G52（Bifrost 二代） | RK3566 | **第一**（ROCKNIX libmali+Vulkan 已验证） | 中量可玩 |
| Mali-G610（Valhall/CSF） | RK3588 | **第二**（开源 PanVK/Panthor 已成熟，Batocera 已切换） | 中重量可玩 |

## 本仓库定位

本仓库 = **原厂闭源 BSP 阵营的 Amlogic 分支**，默认第三志愿（libmali + GLES），面向"主线内核不稳定、但有 Amlogic 厂商内核（与 CoreELEC 同源）可用"的电视盒子/开发板。少数芯片（如 RK356x）可改开 Vulkan 冲第一志愿。

## 已支持/适配中型号

| 型号 | 芯片 | GPU | 默认志愿 | 规格 | 固件 |
|---|---|---|---|---|---|
| X98mini | Amlogic S905W2 (S4) | Mali-G31 | 第三（闭源 BSP + GLES） | 4G+32G、2×USB2.0、TF 卡槽、百兆以太网、WiFi/蓝牙（W522A）、音源 HDMI/AV | [下载](https://github.com/w2xg2022/EmuELEC/releases?q=X98mini&expanded=true) |
| E900V22C | Amlogic S905L3A (G12A) | Mali-G31 | 第三（闭源 BSP + GLES） | 2G+8G、2×USB2.0、百兆以太网、WiFi/蓝牙（UWE5621DS）、音源 HDMI/AV、PSP 可玩 | [下载](https://github.com/w2xg2022/EmuELEC/releases?q=E900V22C&expanded=true) |

> 每个型号各自发布独立 Release（tag 形如 `<型号>-<run id>`），**不要用
> `releases/latest`**——那只会指向最后完成的那个型号，另一个型号会下载到错的固件。
> 上表的链接已按型号筛选，取列表最上方那笔即为该型号最新版。

## 写入 eMMC（免 U 盘开机）

把从 U 盘运行的固件装进盒子内部 eMMC，之后不插盘也能开机。目前 X98mini、E900V22C
均已实机验证通过。

```sh
installtoemmc.sh <型号>     # 例: installtoemmc.sh e900v22c
installtoemmc.sh list       # 列出支持的型号
```

详细原理、分区选择、踩过的坑见 [docs/emmc-install.md](docs/emmc-install.md)。

> ⚠️ **装完之后，每次想从 eMMC 开机都要物理拔掉 U 盘。** bootloader 每次开机固定按
> SD → USB → eMMC 顺序尝试，U 盘只要插着就永远优先——这是刻意保留的安全网（eMMC 装坏了
> 插回 U 盘就能救），代价是软件重启（ES 菜单/`reboot`）不会帮你拔卡，只会又从 U 盘起来。

## 云编译

通过 GitHub Actions 编译（`.github/workflows/build-emuelec.yml`），手动触发
（workflow_dispatch），三个参数：

| 参数 | 说明 |
|---|---|
| `models` | 要编译的型号，空格分隔。留空则用 repo variable `MODELS`，再留空则预设 `X98mini E900V22C` |
| `rebuild_kernel` | 强制重编内核+initramfs。平常不用，只在缓存的 KERNEL 出问题时用一次 |
| `seed_from` | **新型号首次建置**时从哪个兄弟型号借 base（工具链+userland），省掉从零编。留空=不借。只对同 DEVICE 有效，例：`X98mini`。⚠️ 尚未端到端验证，首次使用须核对产物的 dtb/kernel 确实属于本型号 |

> 每月自动重编的 cron 目前是**停用**状态（适配期间避免干扰，见 workflow 内注释）；
> 逻辑已写好，取消注释即可启用。

建置速度靠两层快取：`build-state-<型号>`（接力 checkpoint，工具链+userland）与
`kernel-state-<型号>-<hash>`（kernel 与耦合驱动的原子 bundle）。命中时两个型号并行
约 18 分钟完成；这些 Release 是基础设施，**清理旧固件时切勿删除**。

本地编译指令范例：
```
PROJECT=Amlogic-ce DEVICE=Amlogic-no SUBDEVICE=E900V22C ARCH=aarch64 DISTRO=EmuELEC make image
```
> ⚠️ **别带 `IMAGE_SUFFIX`**——`SUBDEVICE` 已经会自动加一次型号后缀，再带会变成
> `-E900V22C-E900V22C` 这种双后缀的废档名。

固件命名格式：`EmuELEC-Amlogic-no.aarch64-<版本>-<型号名>.img.gz`

## 新增型号步骤

1. 在 `projects/Amlogic-ce/devices/Amlogic-no/bootloader/subdevice_config.sh` 加一个 case 分支，指定该型号对应的 `DEVICE_DTB`。
2. 把型号名加进 repo variable `MODELS`（多个型号用空格分隔）。
3. **首次编译带上 `seed_from`**（填一个同 DEVICE 的既有型号，如 `X98mini`）。新型号还没有自己的
   `build-state` checkpoint，不借 base 就得从零编工具链+约 500 个 userland 套件——实测会撞上
   runner 的 6 小时上限而失败。
4. ⚠️ **首次用 `seed_from` 出的固件必须人工核对**：产物的 dtb/kernel 要确实属于本型号，而不是
   来源型号的。这个坑是**静默**的——借来的 kernel 若没被正确作废，编译完全不报错，但刷上去开不了机。
5. 之后该型号就有自己的 checkpoint 了，往后编译不必再带 `seed_from`。

## 使用说明

- [手柄按键说明](docs/controller-guide.md) —— 手柄 A/B/X/Y 的三层处理（界面/热键/游戏内）、两种布局侦测、热键组合与游戏内位置对齐，附示意图。

## 参考仓库清单

| 仓库 | 阵营 / 用途 |
|---|---|
| [w2xg2022/rocknix](https://github.com/w2xg2022/rocknix) | **第一志愿**：原厂闭源 BSP + Vulkan（libmali）。掌机类 SoC（如 RK3566）首选，PSP 天花板最高 |
| [w2xg2022/armbian](https://github.com/w2xg2022/armbian) | 社区开源阵营：Armbian 固件打包（fork 自 ophub/amlogic-s9xxx-armbian） |
| [w2xg2022/armbian-kernel](https://github.com/w2xg2022/armbian-kernel) | 社区开源阵营：Armbian 主线内核源码（fork 自 ophub/linux-6.18.y） |
| [w2xg2022/es4all-1key](https://github.com/w2xg2022/es4all-1key) | 一键把 Armbian 变复古游戏机的安装脚本 |
| [EmuELEC/EmuELEC](https://github.com/EmuELEC/EmuELEC) | 本仓库的上游项目 |
| [CoreELEC/CoreELEC](https://github.com/CoreELEC/CoreELEC) | 原厂闭源 BSP 内核来源（本仓库的 Amlogic-ce/Amlogic-no 项目直接拉取其 linux-amlogic 内核） |
