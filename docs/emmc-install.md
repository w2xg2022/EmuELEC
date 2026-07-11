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

## 7. 相关文件
- 脚本：`packages/sx05re/emuelec/bin/installtoemmc.sh`
- cfgload 源码：`projects/Amlogic-ce/devices/Amlogic-no/bootloader/scripts/Generic_cfgload.src`
- 原厂 autoscript（含 `cfgloademmc`）：`projects/Amlogic-ce/devices/Amlogic-no/bootloader/scripts/aml_autoscript.src`
- init 里 `disk=`/`mount_storage` 解析：`packages/sysutils/busybox/scripts/init`
