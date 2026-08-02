# 写入 eMMC（内置存储双开机）说明

> 面向：把从 SD/U 盘运行的 EmuELEC 装进电视盒子的**内部 eMMC**，之后不插卡也能开机。
> 统一脚本：`/usr/bin/installtoemmc.sh`（源码 `packages/sx05re/emuelec/bin/installtoemmc.sh`）。
> 一支程序 + 内置 board 表，加机型只加一条 case，**不要一个型号一支脚本**。

## 0. 一句话结论
```sh
installtoemmc.sh x98mini      # 装到 eMMC（也可 -x98mini / auto / list）
poweroff                      # 关机，拔掉 SD/U 盘，再通电即从 eMMC 开机
```
装错/开不了机没关系：**bootloader/env 全程没动，插回 SD/U 盘就照旧从卡开机**。

> ⚠️ **上面这句只适用于 `METHOD="reuse"` 的锁机 Amlogic 盒子**（X98mini / E900V22C）。
> `METHOD="repartition"` 的板子（MD1000）会**整颗重新分区**，装完**不再能从 U 盘开机**，
> 救援只剩 MASKROM。差别很大，先读 [3.2](#32-md1000-具体细节)。

## 1. 用法
```sh
installtoemmc.sh <board>    # 指定机型，如 installtoemmc.sh x98mini
installtoemmc.sh -<board>   # 等效，如 installtoemmc.sh -x98mini
installtoemmc.sh auto       # 按 eMMC 分区布局自动识别机型
installtoemmc.sh list       # 列出支持的机型
```
会打印将要格式化的两个分区、要求手动输入大写 `YES` 才动手，其它任何输入都中止。

## 2. 原理（为什么这样做）
这类锁机盒子（X98mini 等）的 Amlogic 分区表是**私有/锁定**的：
- 官方 CoreELEC 的 `ceemmc` 工具**不认这些盒子的 Android 分区布局**（会 segfault）。
- 原厂 u-boot **不读 MBR**、也**不能重新分区**（parted 建的 MBR 会被无视）。

所以不重新分区，而是**重用两个现成的工厂 Android 命名分区**：
- 一个够大的 → 重新格成 **FAT32，卷标 `CE_FLASH`**（放 kernel.img / dtb.img / SYSTEM / cfgload）
- 最大的一个 → 重新格成 **ext4，卷标 `CE_STORAGE`**（持久化 `/storage`）

开机链：原厂 u-boot 的 `aml_autoscript` 里有 `cfgloademmc`，会扫 eMMC 分区 `mmc 1:1..1F` 找带 `cfgload` 的 FAT 分区；找到就 `setenv ce_on_emmc yes` 并 `source` 它 → `bootm` 我们的 kernel。**不替换 bootloader、不动 env**。

脚本把当前 `/flash` + `/storage` 复制到这两个分区，`cfgload` 里已有分支：
```
if test "${ce_on_emmc}" = "yes"; then
  setenv rootopt "... boot=LABEL=CE_FLASH disk=LABEL=CE_STORAGE"
fi
```
即从 eMMC 开机时用 `CE_FLASH`/`CE_STORAGE` 两个卷标挂载，从 SD/U 盘开机时仍用 `EMUELEC`/`STORAGE`——同一份 cfgload 两用。

## 3. X98mini 具体细节
| 项 | 值 |
|---|---|
| CE_FLASH（boot） | `/dev/super`（Android `super` 分区，约 2.25GB）→ FAT32 |
| CE_STORAGE（数据） | `/dev/userdata`（约 26GB）→ ext4 |
| 大小防呆 | super 1500–4000MB、userdata ≥10000MB，超出范围拒跑 |

**重点：`/dev/super` 是 Android 动态分区容器**。CoreELEC 的 `opentee_linuxdriver.service`（`tee-loader`/`dovi-loader`）开机会用 device-mapper 把它拆成 `dynpart-*` 并挂到 `/android/{system,vendor,odm,oem}`，跑 TEE supplicant + Dolby Vision，把 super 占住格式化不了。脚本里 `teardown_android_super()` 会先：停 service → 杀掉跑在 `/android` 上的进程 → `umount`（必要时 `-l`）→ `dmsetup remove` 各 dynpart，才能格式化 super。**代价 = eMMC 上没有 TEE / Dolby Vision**，retro 游戏机用不到，可接受。此逻辑由 board 表里的 `SUPER_TEARDOWN="yes"` 开关控制，别的机型默认不做。

装完 eMMC 一切正常：ES、蓝牙（[[docs/vm-build-bluetooth.md]] 的 hci_aml）、WiFi（aml_w1）、乙太、26GB storage 全在（蓝牙的 `/storage/bt-*` 也随 `/storage` 一起搬过去）。

## 3.1 E900V22C 具体细节
| 项 | 值 |
|---|---|
| CE_FLASH（boot） | `/dev/system`（工厂 system 分区，1GB）→ FAT32 |
| CE_STORAGE（数据） | `/dev/data`（工厂 data 分区，5.4GB）→ ext4 |
| 大小防呆 | system 900–1100MB、data ≥4000MB，超出范围拒跑 |

跟 X98mini 不同：这台 8GB eMMC 只有一个够大的工厂分区（`data`），没有 Android `super` 动态分区，不需要 `teardown_android_super()`。`system` 只有 1GB，完整版固件的 SYSTEM 塞不下——EmuELEC 默认构建（`EMMC_SLIM=yes`，见 `packages/sx05re/emuelec/package.mk`）已经把 SYSTEM 压到能塞进去，装前脚本会自动检查大小，塞不下会直接拒绝并说明原因，不会走到一半才失败。

## 3.2 MD1000 具体细节

**这台跟上面两台是两套不同的方法**。MD1000 是 RK3566、GPT 分区表、而且 u-boot 是我们自己的，
不存在「分区表不能动」的限制，所以 board 表里它是 `METHOD="repartition"`：
**装出来的就是与 U 盘映像完全相同的三分区**。

| 项 | 值 |
|---|---|
| p1 | FAT32, 卷标 `EMUELEC`, 2GiB —— KERNEL / SYSTEM / dtb / extlinux |
| p2 | ext4, 卷标 `STORAGE`, 6GiB —— 持久化 `/storage` |
| p3 | ext4, 卷标 `EEROMS`, 其余约 21GiB —— ROM 库，挂在 `/storage/roms` |
| 起始位置 | 沿用原本 p1 的起始磁区（读回来的，不写死），前面的 bootloader 保留区不碰 |

### 为什么分区顺序不能改

`eemount`（上游的 ROM 挂载工具）找 EEROMS **不是先看卷标**。它的顺序是（`src/eemount.c`）：

1. `/storage/.update` 底下那颗分区
2. **把 `/flash` 的装置名最后一个字元换成 `3`** —— 纯字串加工，`/dev/mmcblk0p1` → `/dev/mmcblk0p3`
3. 最后才 `LABEL=EEROMS`（日志自己写 `Last hope, we cannot guarantee it's the correct EEROMS`）

第 2 步只有在「ROM 分区真的是第三颗」时才对。曾经的布局在前面多留一个 BOOT 分区
（`p1 BOOT / p2 EMUELEC / p3 STORAGE`），第 2 步就把 **STORAGE 挂到了 `/storage/roms`**，
症状是 **ES 一个游戏都看不到**，极容易被误判成「ROM 扫描坏了」。

⚠️ **加第四颗 EEROMS 分区并不能修好它** —— 第 2 步会先成功，永远走不到卷标那一步。
所以解法只有一个：**保持映像原本的三分区顺序**，让那条启发式天生命中。

### 开机链：extlinux，不是 boot.scr

这颗 u-boot 有 `scan_dev_for_extlinux`（dump bootloader 区确认过），而且在没有分区标 bootable 时
会扫 p1；EmuELEC 映像本来就自带 `/flash/extlinux/extlinux.conf`。**所以不需要 boot.scr、
也不需要 mkimage**（盒子上没有 mkimage）。安装器只做一件事：把 `extlinux.conf` 里的
`boot=` / `disk=` 改指向新分区的 **UUID**。

用 UUID 不用卷标是刻意的：装完 U 盘很可能插回来当外接 ROM 碟，那时**两颗碟都叫
`EMUELEC` / `STORAGE`**，用卷标就是抛硬币。

### ⚠️ 装完就回不去 U 盘开机

这台的 u-boot **读不到 U 盘**。一直以来从 U 盘跑 EmuELEC，靠的是 eMMC 上 Armbian 的
`/boot` 把内核载起来（链载）。新方案从 p1 起整颗抹掉，那个 `/boot` 没了之后，
**插回 U 盘也开不了机**，救援只剩 MASKROM 重刷。
bootloader 保留区（DRAM 时序已校准）全程不碰，所以 MASKROM 这条路一定还在。

安装器的确认画面会把这段用大写讲明白，**这跟锁机盒子那两台的语意完全不同**，别照抄印象。

### ROM 与档案系统

- EEROMS 用 **ext4**（不是映像里的 vfat）：①没有 4GiB 单档上限（PS2/DC/PSP 会超过）
  ②后续要做的「内外部盘聚合」是在 ROM 树上叠 overlay，**upperdir 需要 xattr**，
  而外接碟多半是 FAT 只能当唯读的下层，所以可写的那层必须是内建这颗。
  安装器会写 `/flash/ee_fstype`（`mount_romfs.sh` 读它；`eemount` 自己会探测）。
- **游戏不复制**：只在 p3 建出各平台的空目录（少了它 ES 会一直报
  `System "xxx" path does not exist`）。要不要搬几十 GB 的游戏是使用者的决定，
  可以事后用 Samba 复制，或把 U 盘插回来手动搬。
- ⚠️ **旧 U 盘不能直接当外接 ROM 碟**：它的 ROM 分区卷标还是 `EEROMS`，而
  `eemount`（`src/drive.c`）与 `mount_romfs.sh`（`find ... -not -path .../EEROMS/*`）
  **都会跳过叫 EEROMS 的碟** —— 那个名字保留给内建那颗。要拿它当外接库，得
  ①换个卷标 ②游戏改放在碟上的 `roms/` 子目录（外接扫的是 `*/roms/`，而 U 盘上
  游戏目录是直接放在根目录的，那是**内建碟**的布局）③在该 `roms/` 里放一个空档
  `emuelecroms` 当标记。安装器结束时会把这段印出来。

## 4. 加一个新机型
在脚本的 `board_config()` 里加一条 case，并把机型名加进 `BOARDS`：
```sh
BOARDS="x98mini newbox"

board_config() {
    SUPER_TEARDOWN=""
    case "$1" in
    x98mini) ... ;;
    newbox)
        FLASH_DEV="/dev/xxx"        # 重用的 FAT boot 分区，需 ≥1.5GB（放 1.3GB 的 SYSTEM）
        STORAGE_DEV="/dev/yyy"      # 重用的数据分区
        FLASH_MIN_MB=...; FLASH_MAX_MB=...
        STORAGE_MIN_MB=...
        SUPER_TEARDOWN="yes"        # 仅当 FLASH_DEV 是 Android super 动态分区容器时
        DESC="..."
        ;;
    esac
}
```
选分区的原则：CE_FLASH 需要一个 ≥1.5GB 的分区（要塞 1.3GB 的 SYSTEM squashfs），CE_STORAGE 用最大的那个；两个都必须是 EmuELEC 不在跑的分区（否则要像 super 那样先 teardown）。

## 5. 踩过的坑（都已修）
1. **EmuELEC 的 busybox 没有 `blockdev`/`findmnt`**（原 `x98mini-installtoemmc.sh` 用了它们，所以从没在实机跑通）。改用 `/sys/class/block/<名>/size`（512B sector，`/2048=MB`）+ `/proc/mounts`。
2. **super 被 Android dm/TEE 占住**：见上 `teardown_android_super()`。
3. **首刷卡在 `mount_storage: Could not mount /dev/CE_STORAGE`**：cfgload 的 eMMC 分支原本是 `disk=FOLDER=/dev/CE_STORAGE`（ceemmc 的「storage 是分区上的文件夹」布局），但我们是独立 ext4 贴卷标 `CE_STORAGE`，没有 `/dev/CE_STORAGE` 节点。**根本修复 = 改 `projects/Amlogic-ce/devices/Amlogic-no/bootloader/scripts/Generic_cfgload.src` 第 12 行 `FOLDER=` → `disk=LABEL=CE_STORAGE`**（跟 SD 的 `disk=LABEL=STORAGE` 同理）。这样 image 里的 cfgload 就是对的，脚本 `cp -a /flash/.` 照抄即正确，**盒子上不需要 mkimage**。
   - 盒子上没有 `mkimage`，改这行要在**VM/构建机**上重建 cfgload：
     ```sh
     mkimage -A arm -O linux -T script -C none -n cfgload \
       -d Generic_cfgload.src cfgload
     ```

## 6. 测试与回退
1. `installtoemmc.sh x98mini` → 输入 `YES` → 等复制（`/flash`≈1.3G + `/storage`视数据量，几分钟）。
2. `poweroff` → **拔掉 SD/U 盘** → 通电开机 → 原厂 u-boot `cfgloademmc` 找到 eMMC 上的 cfgload → 从 eMMC 开机。
3. 验证：`awk '$2=="/flash"||$2=="/storage"{print}' /proc/mounts` 应显示 `/dev/super`、`/dev/userdata`。
4. **开不了机就把 SD/U 盘插回去**照旧从卡启动（脚本没动卡）。
5. 想彻底恢复 Android / 重来：用 USB Burning Tool 重刷原厂固件。

## 7. 常见问题

**装完 eMMC 后，重启（ES 菜单或 `reboot` 命令）却还是回到 SD/U 盘的系统，进不了 eMMC？**

这是设计上的固定行为，不是 bug：`aml_autoscript.src` 的 `bootcmd` 每次开机都按 `bootfromsd → bootfromusb → bootfromemmc` 的**固定顺序**依次尝试，SD/U 盘只要还插着且能开机，就永远会在到达 eMMC 那一步之前就已经成功——这是刻意设计的安全网（装错/装坏 eMMC 时插回 SD/U 盘还能救），代价是**只要 SD/U 盘插着，就没有办法开进 eMMC**。

单纯软件重启（ES 菜单的重启、`reboot` 命令）**不会**帮你把 SD/U 盘拔掉，所以：
- 要开进 eMMC → **关机，物理拔掉 SD/U 盘，再通电**。这一步不是装完 eMMC 后做一次就好，**之后每次想用 eMMC 开机都要这样做**。
- 想改用 SD/U 盘 → 插回去，随时都能立刻夺回开机权（这条方向反而不受软重启限制，SD/U 盘一插上电就走它）。

如果你的场景是"eMMC 装完想马上验证"：先 `poweroff`，确认 SD/U 盘已经物理拔出，再通电。用带屏幕/HDMI 直接看开机过程最保险；纯远程操作容易忽略"插着卡"这件事。

## 8. 相关文件
- 脚本：`packages/sx05re/emuelec/bin/installtoemmc.sh`
- cfgload 源码：`projects/Amlogic-ce/devices/Amlogic-no/bootloader/scripts/Generic_cfgload.src`
- 原厂 autoscript（含 `cfgloademmc`）：`projects/Amlogic-ce/devices/Amlogic-no/bootloader/scripts/aml_autoscript.src`
- init 里 `disk=`/`mount_storage` 解析：`packages/sysutils/busybox/scripts/init`
