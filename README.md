# EmuELEC w2xg2022 Edition

本仓库基于上游 [EmuELEC](https://github.com/EmuELEC/EmuELEC) 二次开发，为适配的电视盒子/开发板等ARM设备提供云编译固件。

## 选型策略：三级志愿

归纳长期玩机经验，建议按以下顺序逐级尝试：

1. 🥇 **Armbian + ES4A**（见 [w2xg2022/armbian](https://github.com/w2xg2022/armbian)、[w2xg2022/es4armbian-1key](https://github.com/w2xg2022/es4armbian-1key)）
   主线内核 Armbian，跑 EmulationStation 前端。最通用——Armbian 本身很流行，还能当 Server 用，优先选这条路。
2. 🥈 **EmuELEC（本仓库）**
   当主线内核对某型号支持还不成熟（不稳定、缺驱动，常见于厂商自家 WiFi 芯片-UWE5621DS）时，改用 Amlogic 厂商内核（与 CoreELEC 同源），换取稳定性。
3. 🥉 **Android + Pegasus**
   连 EmuELEC 都跑不起来的型号（如 HiSilicon 芯片、锁机、RK3288等纯 32 位老芯片），保留原厂 Android 系统，装 Pegasus 前端做模拟器启动器。

## 本仓库定位

本仓库 = **第二志愿**。收录"主线内核不稳定、但有 Amlogic 厂商内核（CoreELEC 同源）可用"的型号。

## 已支持/适配中型号

| 型号 | 芯片 | 状态 |
|---|---|---|
| X98mini | Amlogic S905W2 (S4) | 适配中 |

## 云编译

通过 GitHub Actions 自动编译（`.github/workflows/build-emuelec.yml`），支持：
- 手动触发，可指定要编译的型号（workflow_dispatch 的 `models` 参数）
- 每月 1 号自动全部型号重新编译一次（跟上游同步）

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

| 仓库 | 用途 |
|---|---|
| [w2xg2022/armbian](https://github.com/w2xg2022/armbian) | 第一志愿：Armbian 固件打包（fork 自 ophub/amlogic-s9xxx-armbian） |
| [w2xg2022/armbian-kernel](https://github.com/w2xg2022/armbian-kernel) | 第一志愿：Armbian 主线内核源码（fork 自 ophub/linux-6.18.y） |
| [w2xg2022/es4armbian-1key](https://github.com/w2xg2022/es4armbian-1key) | 一键把 Armbian 变复古游戏机的安装脚本 |
| [w2xg2022/fnnas](https://github.com/w2xg2022/fnnas) | FnOS/飞牛NAS 固件（与 armbian 共用 dtb/板级定义） |
| [EmuELEC/EmuELEC](https://github.com/EmuELEC/EmuELEC) | 本仓库的上游项目 |
| [CoreELEC/CoreELEC](https://github.com/CoreELEC/CoreELEC) | Amlogic 厂商内核来源（本仓库的 Amlogic-ce/Amlogic-no 项目直接拉取其 linux-amlogic 内核） |
