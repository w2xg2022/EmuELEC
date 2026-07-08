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

| 型号 | 芯片 | GPU | 默认志愿 | 固件 |
|---|---|---|---|---|
| X98mini | Amlogic S905W2 (S4) | Mali-G31 | 第三（闭源 BSP + GLES） | [下载 .img.gz（约 1.25GB）](https://github.com/w2xg2022/EmuELEC/releases/download/X98mini-28893810285/EmuELEC-Amlogic-no.aarch64-4.8-Piers_devel_20260707194801-X98mini.img.gz) |

## 云编译

通过 GitHub Actions 自动编译（`.github/workflows/build-emuelec.yml`），支持：
- 手动触发，可指定要编译的型号（workflow_dispatch 的 `models` 参数）
- 每月 1 号自动全部型号重新编译一次（跟上游同步；适配期暂时停用，见 workflow 内注释）

编译指令范例：
```
PROJECT=Amlogic-ce DEVICE=Amlogic-no SUBDEVICE=X98mini IMAGE_SUFFIX=X98mini ARCH=aarch64 DISTRO=EmuELEC make image
```

固件命名格式：`EmuELEC-Amlogic-no.aarch64-<版本>-<型号名>.img.gz`

## 新增型号步骤

1. 在 `projects/Amlogic-ce/devices/Amlogic-no/bootloader/subdevice_config.sh` 加一个 case 分支，指定该型号对应的 `DEVICE_DTB`。
2. 把型号名加进 repo variable `MODELS`（多个型号用空格分隔）。
3. 手动触发一次 workflow 验证编译是否成功，再观察自动月编译是否正常。

## 参考仓库清单

| 仓库 | 阵营 / 用途 |
|---|---|
| [w2xg2022/armbian](https://github.com/w2xg2022/armbian) | 社区开源阵营：Armbian 固件打包（fork 自 ophub/amlogic-s9xxx-armbian） |
| [w2xg2022/armbian-kernel](https://github.com/w2xg2022/armbian-kernel) | 社区开源阵营：Armbian 主线内核源码（fork 自 ophub/linux-6.18.y） |
| [w2xg2022/es4all-1key](https://github.com/w2xg2022/es4all-1key) | 一键把 Armbian 变复古游戏机的安装脚本 |
| [EmuELEC/EmuELEC](https://github.com/EmuELEC/EmuELEC) | 本仓库的上游项目 |
| [CoreELEC/CoreELEC](https://github.com/CoreELEC/CoreELEC) | 原厂闭源 BSP 内核来源（本仓库的 Amlogic-ce/Amlogic-no 项目直接拉取其 linux-amlogic 内核） |
