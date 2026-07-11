# VM 编译指南 —— 蓝牙(aml W1 / hci_aml backport)测试用

> 面向：在 VM 上编译 EmuELEC(X98mini / Amlogic-no)以测试内建蓝牙 backport 的 session。
> 结论先讲：**改了 kernel patch/config/DTS 必须清掉整个 `.stamps/linux` 再重编**（否则不会重套 patch）；
> 只验证「能不能编过」用 `./scripts/build linux`（不出映像，最快）；要**上机测**才需要 `make image` 出完整固件烧 SD。

## 0. 连线 & 路径
- VM：`192.168.8.186`，`woody` / `1234`，hostkey `SHA256:PqaOx1S82FLrdSGt/6EB6mbgXQeC+7PoNqbmaJytbCo`
- 文件存取优先用 `Z:\`（`Z:\work\emuelec\EmuELEC` = VM `~/work/emuelec/EmuELEC`）；要跑指令才用 plink
- 建置树：`~/work/emuelec/EmuELEC`
- 建置输出目录：`build.EmuELEC-Amlogic-no.aarch64-4`
- 映像产物目录：`target/`（`*.img.gz` 全新烧录 + `*.tar` 增量更新）
- 设备 X98mini：`192.168.8.171`，`root` / `emuelec`

## 1. 建置环境变量（每次都要带）
```bash
export PROJECT=Amlogic-ce DEVICE=Amlogic-no SUBDEVICE=X98mini IMAGE_SUFFIX=X98mini ARCH=aarch64 DISTRO=EmuELEC
export CONCURRENCY_MAKE_LEVEL=6
```

## 2. 逐包编译 vs 整包
- 只编某个包（不出映像）：`./scripts/build <包名>`
- 出完整映像：`make image`（重用所有 stamp，只重编有改动的包 → 增量很快）

## 3. stamp 机制（关键，别踩坑）
每个包的完成标记在 `build.EmuELEC-Amlogic-no.aarch64-4/.stamps/<包名>/`。
- **改了「源码 / patch / config / DTS」→ 必须清掉该包整个 stamp**，否则不会重跑 unpack/patch：
  ```bash
  rm -rf build.EmuELEC-Amlogic-no.aarch64-4/.stamps/linux
  ```
  清掉后 `./scripts/build linux` 会：重新解压源码（从 `sources/` 本地缓存，**不重新下载**）→ **重新套用所有 patch**（含你新加的 BT patch）→ 重编。
- ⚠️ 只清 `.stamps/linux/build_target` **只会重编、不会重套 patch**。你改的是 patch/DTS，所以要清 **整个** `.stamps/linux`。
- ⚠️ 别清整个 `.stamps/`（会全量重编几百个包）。只清你动到的包。
- ⚠️ 别删 `sources/`（下载缓存，有些镜像已死，重下很慢）。

## 4. 蓝牙改动 → 对应哪个包
| 你改的文件 | 属于哪个包 | 说明 |
|---|---|---|
| `packages/linux/patches/linux-200-…hci-uart-bt.patch` | **linux** | kernel patch |
| `common_drivers/patches/common_drivers-100-…w155s2-bt.patch`（DTS serdev 节点） | **linux** | **dtb 在 kernel build 内产出**，common_drivers 随 kernel 编 → 归 linux 包 |
| `projects/Amlogic-ce/devices/Amlogic-no/linux/linux.aarch64.conf` | **linux** | 内核 config（`CONFIG_BT_HCIUART_AML=y` 等） |
| `packages/linux-firmware/…/aml-w155s2-bt-firmware` | **aml-w155s2-bt-firmware** | 固件包，已在 `projects/Amlogic-ce/devices/Amlogic-no/options` 的 `FIRMWARE=` 清单 |

> **kernel + dtb 是同一个 `linux` 包**：改 patch、改 config、改 DTS 都清 `.stamps/linux` 一次即可全部生效。

## 5. 最快：只验证 kernel patch 能不能编过（不出映像）
```bash
cd ~/work/emuelec/EmuELEC
export PROJECT=Amlogic-ce DEVICE=Amlogic-no SUBDEVICE=X98mini IMAGE_SUFFIX=X98mini ARCH=aarch64 DISTRO=EmuELEC CONCURRENCY_MAKE_LEVEL=6
rm -rf build.EmuELEC-Amlogic-no.aarch64-4/.stamps/linux    # 强制重解压 + 重套 patch
./scripts/build linux                                      # 只编内核(含 dtb)，不出映像
```
- patch 套用失败 → 停在解压阶段（看是哪个 hunk 冲突）。
- 编译失败 → 看报错（backport 到 5.15 最常见是缺 API / 头文件宏，见蓝牙 memory 记录的 skb_pull_data / H4_RECV_ISO 两处补丁）。

### 后台跑法（长时间别卡终端）
```bash
cat > ~/tmp/ktest.sh <<'EOF'
#!/bin/bash
cd ~/work/emuelec/EmuELEC || exit 1
export PROJECT=Amlogic-ce DEVICE=Amlogic-no SUBDEVICE=X98mini IMAGE_SUFFIX=X98mini ARCH=aarch64 DISTRO=EmuELEC CONCURRENCY_MAKE_LEVEL=6
echo "=== START $(date) ==="
./scripts/build linux
echo "=== END $(date) rc=$? ==="
EOF
chmod +x ~/tmp/ktest.sh
nohup setsid bash ~/tmp/ktest.sh > ~/tmp/ktest.log 2>&1 < /dev/null &
```
用 `tail -f ~/tmp/ktest.log` 看进度，`pgrep -f ktest.sh` 看是否还在跑。

## 6. 要上机测蓝牙 → 出完整映像
kernel 没法热换（SYSTEM 是只读 squashfs），所以测 BT 要出完整映像再烧 SD：
```bash
./scripts/build aml-w155s2-bt-firmware    # 确保固件包编好、进 FIRMWARE 清单
make image                                # linux 已编好 → 只组映像，快
```
- 产物：`target/EmuELEC-Amlogic-no.aarch64-<ver>-…-X98mini*.img.gz`（+ `.tar`）
- 烧 SD → 上机（`192.168.8.171` root/emuelec）→ 验证：
  ```bash
  dmesg | grep -iE "aml|hci|serdev|firmware|bluetooth"
  hciconfig -a          # 期望看到 hci0
  ```
- 重点观察（见蓝牙 memory）：① serdev 是否自动生 hci0（vendor `amlogic,meson-uart` 能否让 serdev 挂上是最大风险）；② 固件 UART 下载 115200→4M 是否成功；③ 失败先看上面 dmesg grep。

## 7. 规矩 / 注意
- 用户 CLAUDE.md：**改完等指令再编**，别自己闷头开编。
- 编译前确认 VM 磁盘空间够（全量 image 吃空间）。
- 若 serdev 挂不上、内建蓝牙一时搞不定，退路是 **USB 蓝牙 dongle**（btusb 直接支持，零改动）。
