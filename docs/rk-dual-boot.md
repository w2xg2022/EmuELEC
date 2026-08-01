# Rockchip 双系统切换（Armbian ⇄ EmuELEC）

> English version: [rk-dual-boot.en.md](rk-dual-boot.en.md)
>
> ★脚本本身（`rk-dualboot/` 底下那几个档）的注释与萤幕输出一律为英文★，
> 因为它们面向上游与其它 RK 机型的使用者。本文是那份文档的简体中文对照。

给「**原厂 u-boot 扫不到 USB**」那类 Rockchip 板子的缝合方案：**eMMC 装 Armbian、
U 盘装 EmuELEC**。由 eMMC 上那颗 DRAM 时序已校准、保开机的 vendor u-boot 用 `booti`
链载 EmuELEC。一个 **TRIGGER 档**决定这次开哪个系统，两边都能一键互切。

不绑机型。在 **MD1000（RK3566）** 上开发与验证，任何有同样限制的 RK 板子都适用；
整套设定里唯一还绑板子的只有内核命令列里的串口，见
[换到别的板子](#换到别的板子)。

> 机制与 [ROCKNIX 那套](https://github.com/w2xg2022/rocknix/blob/next/docs/md1000-dual-boot.md)
> 相同（两者同为 LibreELEC 血统，initramfs 都靠 `boot=` / `disk=` 内核参数找设备），
> 只是换成 EmuELEC 的标签与档名。

## 原理

开机时 `/boot/boot.cmd` 这个 u-boot 脚本先检查 eMMC boot 分区上的 `emuelec/TRIGGER`：

- **有 TRIGGER** → 从 eMMC 载入 `emuelec/KERNEL` + `emuelec/dtb`，`booti` 链载
  EmuELEC，其 rootfs 来自 U 盘（`LABEL=EMUELEC` / `STORAGE`）。
- **没 TRIGGER** → Armbian 照常开机。

> **为什么内核必须放 eMMC**：原厂 u-boot 根本扫不到 USB 设备，永远读不到 U 盘上的
> KERNEL。链载之后内核已经是 Linux，USB 由完整驱动接管，U 盘上的 rootfs 就拿得到了。

> **为什么用 `booti` 不用 `kexec`**：kexec 会把 GPU/显示留成脏状态，下一个系统初始化
> DRM 时整台硬冻结。u-boot 会干净地初始化硬件，这是唯一验证过能跑的路径。

> ### ⚠️ 这个保底能挡什么、不能挡什么
>
> 「链载失败会落回 Armbian」这句话**只在 u-boot 阶段成立**，而且只涵盖两种情况：
> **①没有 TRIGGER**；**②eMMC 上还没铺 KERNEL（`load` 失败）**。
>
> 一旦内核铺上 eMMC，`load` 与 `booti` 都必定成功，u-boot 就此交棒、**不会再回来**：
>
> ```
> if test -e ${devtype} ${devnum} emuelec/TRIGGER; then
> 	load ... emuelec/KERNEL              # 读 eMMC,铺过就一定成功
> 	load ... emuelec/dtb
> 	booti ...                            # 起得来就不 return
> 	echo "falling back to Armbian"       # ← 走不到这一行
> fi
> ```
>
> 所以**拔掉 U 盘救不回来**：内核会起来，然后卡在 initramfs 找不到 rootfs
> （黑屏、无网络）。那已经是**内核阶段**的事，u-boot 管不着。
>
> **实际含义**：eMMC 上一旦放了没验证过的内核，就没有任何软件手段能切回 Armbian
> （TRIGGER 在 eMMC 上，只有跑起来的 Linux 删得掉）。**bring-up 阶段务必准备一张
> 可开机的 Armbian SD 卡**（u-boot 一般 SD 优先于 eMMC；从 SD 开机后挂 eMMC boot
> 分区，删 `emuelec/TRIGGER` 或还原 `boot.{cmd,scr}.armbian-orig`）。否则只剩
> MASKROM 重刷这条路。

## 一键切换

> 两个方向的脚本都在 [`docs/rk-dualboot/`](rk-dualboot/)。

### ▶ Armbian → U 盘 EmuELEC

在 **Armbian** 里跑（需联网、U 盘要插着）：

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/rk-dualboot/switch-to-emuelec.sh | bash
```

> 没 `curl` 就用 `wget -qO- <同一网址> | bash`

**首次运行会自动完成一次性安装** —— 见[首次运行装了什么](#首次运行装了什么)。
之后每次跑就只是「同步 payload、放 TRIGGER、重开」。

### ◀ U 盘 EmuELEC → eMMC Armbian

在 **EmuELEC** 里跑（需联网）。**⚠️ 路径关键**：EmuELEC 的 `/usr` 是只读 squashfs，
脚本要存到可写且持久的 `/storage` 再执行：

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/rk-dualboot/switch-to-armbian.sh -o /storage/switch-to-armbian.sh && sh /storage/switch-to-armbian.sh
```

它会挂 eMMC boot 分区、删掉 `emuelec/TRIGGER`、然后重开。存到 `/storage` 之后
下次直接 `sh /storage/switch-to-armbian.sh` 就行。

## 装成常驻命令（可选）

| 脚本 | 在哪跑 | 装到（可写路径） | 之后切换命令 |
|------|--------|------------------|--------------|
| [`switch-to-emuelec.sh`](rk-dualboot/switch-to-emuelec.sh) | **Armbian** | `/usr/local/sbin/` | `switch-to-emuelec.sh` |
| [`switch-to-armbian.sh`](rk-dualboot/switch-to-armbian.sh) | **EmuELEC** | `/storage/`（`/usr` 只读，必须放这） | `sh /storage/switch-to-armbian.sh` |

## 链载需要的配套档就只有两个

u-boot 从 eMMC 只读这两个：

```
<emmc-boot>/emuelec/KERNEL   内核映像 —— initramfs 就包在里面
<emmc-boot>/emuelec/dtb      设备树,固定用这个档名存放
```

dtb 刻意存成朴素的 `dtb` 而不是原本那个带机型的档名，**这样 u-boot 链载块里就不带
任何机型资讯**。

其余一概不需要：`SYSTEM`、`oemsplash-*.png`、`extlinux/`、`*.md5` 全都是 initramfs
起来之后从 `/flash`（也就是 U 盘本身）读的，那时内核早就跑起来了。

> U 盘上的 dtb 在 boot 分区的**根目录**，因为 EmuELEC 的 `bootloader/mkimage` 是
> `mcopy -o "$dtb" ::`。★ROCKNIX 是放在 `device_trees/` 子目录，别把那个假设搬过来★。

## ★刷了新映像却还在跑旧内核★

这是整套设计必须防的坑。链载读的是 **eMMC** 上那份，而刷新映像只换掉 **U 盘** 上那份，
两者没有任何东西会自动配对。结果是 `/etc/os-release` 显示新版本、实际跑的却是旧内核 ——
而且因为 **initramfs 包在 KERNEL 里面**，内核层与 initramfs 层的修改会全部静默失效，
看起来就像「你的修正没生效」。

三道防线，按触发顺序：

1. **Armbian 上的 `emuelec-chainload-sync.service`**（由 `switch-to-emuelec.sh` 装）。
   **开机与关机各跑一次**。★关机那次才是关键★：惯用流程是「开 Armbian → 写新映像到
   U 盘 → 重开进 EmuELEC」，只在开机同步的话，那次同步发生在写映像**之前**，必然漏掉。
2. **`switch-to-emuelec.sh` 每次运行都同步**，不是只在 eMMC 上还没副本时才做。
3. **EmuELEC 里的 `md1000-kernel-sync.service`**
   （`projects/Rockchip/devices/RK3566/packages/md1000-boot-fixes/`）从另一边做同样的事，
   所以只要进过一次 EmuELEC，之后刷映像就会自愈。日志在 `/emuelec/logs/kernel-sync.log`。

> 判定一律用 **md5，绝不用时间戳** —— 时间戳会被 FAT 分区、时区处理、以及映像的写入
> 方式弄失真。手工核对：`md5sum /flash/KERNEL` 与 eMMC 上那份比一比。

> **同步完要下次开机才生效** —— u-boot 早在任何同步发生之前就已经载入旧内核了。
> 所以刷完新映像要**重开两次**。★验证内核层的修改时，第一件事永远是先确认自己跑的是
> 哪一颗★：
>
> ```bash
> uname -a          # 看建置时间戳,不是只看版本号
> ```

## 首次运行装了什么

`switch-to-emuelec.sh` 首次执行时自动做以下几步，一般无需手动：

1. 把 [`emuelec-chainload-sync.sh`](rk-dualboot/emuelec-chainload-sync.sh) 装到
   `/usr/local/sbin/`，并启用
   [`emuelec-chainload-sync.service`](rk-dualboot/emuelec-chainload-sync.service)。
2. 把 [`boot-emuelec-block.txt`](rk-dualboot/boot-emuelec-block.txt) 插到
   `/boot/boot.cmd` 第一处 `setenv load_addr` **之前**（原档备份为 `*.armbian-orig`），
   再用下面这行重编：
   `mkimage -C none -A arm -T script -n 'flatmax load script' -d /boot/boot.cmd /boot/boot.scr`
   （需要 `mkimage`：`apt-get install -y u-boot-tools`）
3. 把 U 盘 EmuELEC 分区上的 `KERNEL` 与 dtb 复制到 `<emmc-boot>/emuelec/`。

档名的出处：`distributions/EmuELEC/options` 的 `DISTRO_BOOTLABEL="EMUELEC"` 与
`DISTRO_DISKLABEL="STORAGE"`；`config/options` 的 `KERNEL_NAME="KERNEL"`。

> **从旧版升级**：早期版本把 dtb 按机型档名存在 eMMC 上，`boot.cmd` 里也是那个名字。
> `switch-to-emuelec.sh` 会侦测到这种旧块，还原 `boot.cmd.armbian-orig`、重装当前的块、
> 并清掉旧的 dtb 副本 —— 不用手动改，前提是 `*.armbian-orig` 备份还在。

## 换到别的板子

脚本需要的东西都是执行期侦测的，正常情况下一个字都不用改。两个例外有开关：

| 设定 | 在哪 | 什么时候需要 |
|------|------|--------------|
| `EMMC_BOOT_DEV` | 环境变数，预设 `/dev/mmcblk0p1` | eMMC boot 分区不是 `mmcblk0` 的第一个分区 |
| `DTB_NAME` | 环境变数 | 映像里带了**不只一个** dtb，无法推断该用哪个。只有一个时自动认；有多个时同步会**拒绝猜测**并列出候选 —— 猜错 dtb 正是那种会让机器开不了机的静默错误 |

唯一真正绑板子的是 `boot-emuelec-block.txt` 里的串口：

```
setenv bootargs "boot=LABEL=EMUELEC disk=LABEL=STORAGE quiet console=ttyS2,1500000 console=tty0"
```

`ttyS2` 是 RK3566 的除错串口，换别的板子要跟着改。载入位址
（`0x02080000` / `0x08300000`）对 64 位 Rockchip 是通用的，至今没需要动过。

## 保底 / 救援

- **Armbian 还开得起来时**：`rm /boot/emuelec/TRIGGER`，或还原备份：
  ```bash
  cp /boot/boot.cmd.armbian-orig /boot/boot.cmd && cp /boot/boot.scr.armbian-orig /boot/boot.scr
  ```
- **EmuELEC 开不起来（黑屏、无网络）时**：★拔 U 盘没有用★（理由见上面的警告框）。
  按代价由低到高：
  1. 插一张**可开机的 Armbian SD 卡**，从 SD 开机后挂 eMMC boot 分区，删
     `emuelec/TRIGGER` 或还原 `*.armbian-orig`。（u-boot 一般 SD 优先于 eMMC。
     本机尚未实测，属推荐做法不是保证。）
  2. **MASKROM 重刷 Armbian**。一定可行：bootloader、分区表、保留区全程没被动过。
- **想彻底告别 U 盘**：用 `installtoemmc` 把 EmuELEC 装进 eMMC 变单系统。会抹掉
  Armbian rootfs，但保留 u-boot 与 BOOT 分区作为链载宿主与 MASKROM 救援路径。
  见 [docs/emmc-install.md](emmc-install.md)。
