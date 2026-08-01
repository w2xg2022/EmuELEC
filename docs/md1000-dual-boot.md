# MD1000 双系统切换（Armbian ⇄ EmuELEC）

MD1000（RK3566）的缝合方案：**eMMC 装 Armbian、U 盘装 EmuELEC**，eMMC 的 vendor u-boot（DRAM 已校准，保开机）用 `booti` 链载 EmuELEC。一个 **TRIGGER 档**决定这次开哪个系统，两边都能一键互切。

> 机制与 [ROCKNIX 那套](https://github.com/w2xg2022/rocknix/blob/next/docs/md1000-dual-boot.md)完全相同（同为 LibreELEC 血统，initramfs 都靠 cmdline 的 `boot=` / `disk=` 找设备），只是换成 EmuELEC 的标签与档名。

## 原理

eMMC 的 `/boot/boot.cmd`（u-boot 脚本）开机时先检查 eMMC boot 分区上的 `emuelec/TRIGGER`：

- **有 TRIGGER** → 载入 eMMC 的 `emuelec/KERNEL` + dtb，`booti` 链载 EmuELEC（rootfs 从 U 盘 `LABEL=EMUELEC` / `STORAGE`）。
- **没 TRIGGER** → 照常开 Armbian。

> ### ⚠️ 这个保底能挡什么、不能挡什么（★别搞错★）
>
> 「链载失败会自动落回 Armbian」这句话**只在 u-boot 阶段成立**，而且只涵盖两种情况：
> **①没有 TRIGGER**；**②eMMC 上还没铺 `emuelec/KERNEL`（`load` 失败）**。
>
> 一旦内核铺上 eMMC，`load` 必定成功、`booti` 也必定成功 —— u-boot 就此交棒、**不会再回来**：
>
> ```
> if test -e ${devtype} ${devnum} emuelec/TRIGGER; then
> 	load ... emuelec/KERNEL              # 从 eMMC 读，铺过就一定成功
> 	load ... emuelec/rk3566-md1000.dtb
> 	booti ...                            # 起得来就不 return
> 	echo "falling back to Armbian"       # ← 走不到这一行
> fi
> ```
>
> 所以「拔掉 U 盘就能落回 Armbian」是**错的**：拔 U 盘只会让内核起来之后找不到 rootfs
> 而卡在 initramfs（黑屏、无网络），那已经是**内核阶段**的事，u-boot 管不着。
>
> **实际含义**：eMMC 上的 KERNEL 一旦换成没验证过的版本，万一它开不起来，
> 就没有任何软件手段可以切回 Armbian（TRIGGER 在 eMMC 上，只有跑起来的 Linux 删得掉）。
> **bring-up 阶段务必准备一张可开机的 Armbian SD 卡**（u-boot 一般 SD 优先于 eMMC，
> 开进去后挂 `/dev/mmcblk0p1` 删掉 `emuelec/TRIGGER`，或还原 `boot.{cmd,scr}.armbian-orig`），
> 否则只剩 MASKROM 重刷这条路。

> **为什么内核要放 eMMC**：MD1000 出厂的 u-boot **扫不到 USB 设备**，U 盘上的 KERNEL 它读不到。链载之后内核已经是 Linux，USB 由 Linux 完整驱动接管，rootfs（SYSTEM）留在 U 盘就没问题。

> **为什么用 booti 不用 kexec**：kexec 会把 GPU/显示留成脏状态，到初始化 DRM 时整台硬冻结（黑屏）。booti 由 u-boot 干净初始化硬件，是唯一验证过能跑的路径。

## 一键切换（curl 下载即执行）

> 两个方向的脚本在 [`docs/md1000-dualboot/`](md1000-dualboot/)。

### ▶ Armbian → U 盘 EmuELEC

在 **Armbian**（`root` / `1234`，需联网、U 盘要插着）里跑：

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/md1000-dualboot/switch-to-emuelec.sh | bash
```

> 没 `curl` 就用 `wget`：`wget -qO- <同一网址> | bash`

**首次运行会自动完成一次性安装**——检测到 `/boot/boot.cmd` 没链载块时，脚本会：① 从 U 盘把 `KERNEL` + `rk3566-md1000.dtb` 铺到 eMMC `/boot/emuelec/`；② 往 `/boot/boot.cmd` 插链载块、重编 `boot.scr`（自动备份 `*.armbian-orig`）。装好后再 `touch TRIGGER` + `reboot`。之后每次跑就是纯切换。

### ◀ U 盘 EmuELEC → eMMC Armbian

在 **EmuELEC**（`root` / `emuelec`，需联网）里跑。**⚠️ 路径关键**：EmuELEC 的 `/usr` 是只读 squashfs，脚本要存到**可写且持久的 `/storage`** 再执行：

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/md1000-dualboot/switch-to-armbian.sh -o /storage/switch-to-armbian.sh && sh /storage/switch-to-armbian.sh
```

脚本会挂载 eMMC boot 分区（`/dev/mmcblk0p1`）、`rm emuelec/TRIGGER`、然后 `reboot`。
（EmuELEC 是 Linux、有完整 eMMC 存取，所以能删掉 eMMC 上的 TRIGGER；u-boot 才受 USB / ext4write 限制。存 `/storage` 后下次不用再下载，直接 `sh /storage/switch-to-armbian.sh`。）

## 装成常驻命令（可选）

嫌每次 curl 麻烦，可把脚本装到固定位置，之后一句话切换：

| 脚本 | 在哪跑 | 装到（可写路径） | 之后切换命令 |
|------|--------|------------------|--------------|
| [`switch-to-emuelec.sh`](md1000-dualboot/switch-to-emuelec.sh) | **Armbian** | `/usr/local/sbin/`（Armbian rootfs 可写） | `switch-to-emuelec.sh` |
| [`switch-to-armbian.sh`](md1000-dualboot/switch-to-armbian.sh) | **EmuELEC** | `/storage/`（`/usr` 只读，必须放这） | `sh /storage/switch-to-armbian.sh` |

## 首次安装做了什么（原理，脚本已自动完成）

`switch-to-emuelec.sh` 首次运行时自动做以下几步，一般无需手动：

1. 从 U 盘 EmuELEC 的 boot 分区（`LABEL=EMUELEC`）把 `KERNEL` + `rk3566-md1000.dtb`
   复制到 eMMC 的 `/boot/emuelec/KERNEL` 与 `/boot/emuelec/rk3566-md1000.dtb`。
   （★与 ROCKNIX 的差别★：ROCKNIX 的 dtb 在 `device_trees/` 子目录，EmuELEC 的
   `bootloader/mkimage` 是 `mcopy -o "$dtb" ::`，dtb 落在 boot 分区**根目录**。）
2. 备份 `boot.cmd` / `boot.scr` 为 `*.armbian-orig`，把 [`boot-emuelec-block.txt`](md1000-dualboot/boot-emuelec-block.txt)
   插到 `/boot/boot.cmd` 的 `setenv load_addr` 那行**之前**，用
   `mkimage -C none -A arm -T script -n 'flatmax load script' -d /boot/boot.cmd /boot/boot.scr` 重编。
   （需要 `mkimage`；Armbian 上 `apt-get install -y u-boot-tools`）

标签与档名的出处：`distributions/EmuELEC/options` 的 `DISTRO_BOOTLABEL="EMUELEC"`、
`DISTRO_DISKLABEL="STORAGE"`；`config/options` 的 `KERNEL_NAME="KERNEL"`。

## ★刷了新固件却还在跑旧内核★

链载读的是 **eMMC** 上那份 `KERNEL`，而刷新固件只换掉 **U 盘** 上的那份，两者没有任何东西会自动配对。结果是 `/etc/os-release` 显示新版本、实际跑的却是旧内核 —— **initramfs 也包在 KERNEL 里面**，所以内核层与 initramfs 的修改会全部静默失效，极容易误判。

两道防线：

1. `switch-to-emuelec.sh` **每次运行**都比对 md5 并同步（不是只在「eMMC 上还没副本」时才做）。
2. EmuELEC 固件里的 `md1000-kernel-sync.service`（见 `projects/Rockchip/devices/RK3566/packages/md1000-boot-fixes/`）每次开机自己做同样的同步。所以只要进过一次 EmuELEC，之后刷固件就会自愈，日志在 `/emuelec/logs/kernel-sync.log`。

> 判定用 **md5 不用时间戳** —— 时间戳会因为 FAT 分区、时区、复制方式而失真。
> 手工诊断：`md5sum /flash/KERNEL` 与 eMMC `/boot/emuelec/KERNEL` 比一下，不一致就是中招。
> 注意同步完要**下次开机**才生效，本次跑的仍是旧内核（所以刷完固件要多重开机一次）。

## 保底 / 救援

- **还能开进 Armbian 时**：`cp /boot/boot.cmd.armbian-orig /boot/boot.cmd && cp /boot/boot.scr.armbian-orig /boot/boot.scr`，或直接 `rm /boot/emuelec/TRIGGER`。
- **EmuELEC 开不起来（黑屏 + 无网络）时**：★拔 U 盘没有用★（理由见上面「原理」那段的警告框）。
  按代价由低到高：
  1. 插一张**可开机的 Armbian SD 卡**，从 SD 开机后挂 `/dev/mmcblk0p1`，删 `emuelec/TRIGGER`
     或还原 `*.armbian-orig`。（u-boot 一般 SD 优先于 eMMC；本机尚未实测，属推荐做法不是保证。）
  2. **MASKROM 重刷 Armbian**（一定可行；bootloader / 分区表 / 保留区全程没动）。
- 彻底救援：MASKROM 重刷 Armbian（bootloader / 分区表 / 保留区全程没动，一律可救）。
- 想彻底告别 U 盘：用 `installtoemmc` 把 EmuELEC 装进 eMMC 变**单系统**（会抹掉 Armbian rootfs，保留 u-boot + BOOT 作 chainload 宿主与 MASKROM 救援），见 [docs/emmc-install.md](emmc-install.md)。
