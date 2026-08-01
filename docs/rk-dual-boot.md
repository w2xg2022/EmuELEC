# Rockchip dual boot (Armbian ⇄ EmuELEC)

Run **Armbian on eMMC and EmuELEC on a USB stick** on a Rockchip board whose
stock u-boot cannot boot from USB. The vendor u-boot on eMMC — the one whose
DRAM timings are known-good, so the board always comes up — `booti`s into
EmuELEC. A single **TRIGGER file** decides which system boots, and either side
can switch to the other with one command.

Nothing here is tied to a specific model. It was developed and verified on the
**MD1000 (RK3566)**; any RK board with the same constraint should work, and the
only board-specific value in the whole setup is the serial console in the
kernel command line (see [Adapting to another board](#adapting-to-another-board)).

> Same mechanism as the [ROCKNIX setup](https://github.com/w2xg2022/rocknix/blob/next/docs/md1000-dual-boot.md)
> (both are LibreELEC-derived, so the initramfs finds its devices from the
> `boot=` / `disk=` kernel arguments), with EmuELEC's labels and filenames.

## How it works

At boot the u-boot script in `/boot/boot.cmd` checks the eMMC boot partition for
`emuelec/TRIGGER`:

- **TRIGGER present** → load `emuelec/KERNEL` + `emuelec/dtb` from eMMC and
  `booti` into EmuELEC. Its rootfs comes off the USB stick (`LABEL=EMUELEC` /
  `STORAGE`).
- **TRIGGER absent** → Armbian boots as usual.

> **Why the kernel has to live on eMMC**: the stock u-boot cannot see USB devices
> at all, so it can never read the KERNEL on the stick. After the chainload the
> kernel is running Linux, USB is driven properly, and the rootfs on the stick is
> reachable.

> **Why `booti` and not `kexec`**: kexec leaves the GPU/display in a dirty state
> and the machine hard-freezes when the next system initialises DRM. u-boot
> initialises the hardware cleanly; this is the only path that has been verified
> to work.

> ### ⚠️ What the fallback does and does not cover
>
> "A failed chainload falls back to Armbian" is true **only inside u-boot**, and
> only for two cases: **no TRIGGER**, or **no KERNEL on eMMC yet** (so `load`
> fails).
>
> Once a kernel is on eMMC, `load` and `booti` both succeed and u-boot hands off
> for good — it never comes back:
>
> ```
> if test -e ${devtype} ${devnum} emuelec/TRIGGER; then
> 	load ... emuelec/KERNEL              # reads eMMC, always succeeds once installed
> 	load ... emuelec/dtb
> 	booti ...                            # if it starts, it does not return
> 	echo "falling back to Armbian"       # <- never reached
> fi
> ```
>
> So **pulling the USB stick does not rescue you**. The kernel will start and
> then hang in the initramfs looking for a rootfs that is not there — black
> screen, no network. That is a *kernel*-stage failure, outside u-boot's reach.
>
> **In practice**: the moment eMMC holds an unverified kernel, there is no
> software way back to Armbian (TRIGGER lives on eMMC and only a running Linux
> can delete it). **Keep a bootable Armbian SD card around during bring-up**
> (u-boot generally prefers SD over eMMC; boot from it, mount the eMMC boot
> partition, delete `emuelec/TRIGGER` or restore `boot.{cmd,scr}.armbian-orig`).
> Otherwise the only way out is a MASKROM reflash.

## One-command switching

> Both scripts live in [`docs/rk-dualboot/`](rk-dualboot/).

### ▶ Armbian → EmuELEC on USB

Run this in **Armbian** (needs network, stick plugged in):

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/rk-dualboot/switch-to-emuelec.sh | bash
```

> No `curl`? Use `wget -qO- <same url> | bash`

The **first run installs everything automatically** — see
[What the first run installs](#what-the-first-run-installs). Every run after
that just syncs the payload, sets TRIGGER and reboots.

### ◀ EmuELEC on USB → Armbian on eMMC

Run this in **EmuELEC** (needs network). **The path matters**: EmuELEC's `/usr`
is a read-only squashfs, so save the script to the writable, persistent
`/storage` first:

```bash
curl -L https://raw.githubusercontent.com/w2xg2022/EmuELEC/main/docs/rk-dualboot/switch-to-armbian.sh -o /storage/switch-to-armbian.sh && sh /storage/switch-to-armbian.sh
```

It mounts the eMMC boot partition, removes `emuelec/TRIGGER`, and reboots. Once
saved to `/storage` you can just run `sh /storage/switch-to-armbian.sh` next
time.

## Installing as permanent commands (optional)

| Script | Run it in | Install to (writable path) | Then switch with |
|--------|-----------|----------------------------|------------------|
| [`switch-to-emuelec.sh`](rk-dualboot/switch-to-emuelec.sh) | **Armbian** | `/usr/local/sbin/` | `switch-to-emuelec.sh` |
| [`switch-to-armbian.sh`](rk-dualboot/switch-to-armbian.sh) | **EmuELEC** | `/storage/` (`/usr` is read-only) | `sh /storage/switch-to-armbian.sh` |

## The chainload payload is exactly two files

u-boot reads only these from eMMC:

```
<emmc-boot>/emuelec/KERNEL   the kernel image — the initramfs is inside it
<emmc-boot>/emuelec/dtb      the device tree, stored under this fixed name
```

The dtb is deliberately stored as plain `dtb` rather than under its original
model-specific filename, so the u-boot block carries no board name at all.

Nothing else is needed. `SYSTEM`, `oemsplash-*.png`, `extlinux/` and the `*.md5`
files are all read from `/flash` — the USB partition itself — by the initramfs,
which only runs once the kernel is already up.

> On the USB stick the dtb sits in the **root** of the boot partition, because
> EmuELEC's `bootloader/mkimage` does `mcopy -o "$dtb" ::`. ROCKNIX keeps its
> dtbs in a `device_trees/` subdirectory — do not carry that assumption over.

## ★ Flashed a new image but still running the old kernel ★

This is the trap the whole setup has to defend against. The chainload reads the
copy on **eMMC**; flashing a new image only replaces what is on the **USB
stick**. Nothing pairs the two automatically. The machine then reports the new
version in `/etc/os-release` while running the old kernel — and because the
**initramfs is baked into KERNEL**, every kernel-level and initramfs-level change
silently does nothing. It looks like your fix did not work.

Three defences, in the order they fire:

1. **`emuelec-chainload-sync.service` on Armbian** (installed by
   `switch-to-emuelec.sh`). Runs at **every boot and every shutdown**. The
   shutdown run is the important one: the normal workflow is *boot Armbian →
   write a new image to the stick → reboot into EmuELEC*, and a boot-time-only
   sync would have run before the new image was written.
2. **`switch-to-emuelec.sh`** syncs on **every** run, not only when eMMC has no
   copy yet.
3. **`md1000-kernel-sync.service` inside EmuELEC**
   (`projects/Rockchip/devices/RK3566/packages/md1000-boot-fixes/`) does the same
   from the other side, so once you have booted EmuELEC even once, later flashes
   self-heal. Its log is `/emuelec/logs/kernel-sync.log`.

> Comparison is by **md5, never timestamps** — timestamps are skewed by the FAT
> partition, by timezone handling and by however the image was written.
> Manual check: compare `md5sum /flash/KERNEL` against the eMMC copy.

> **A sync only takes effect on the NEXT boot** — u-boot loaded the old kernel
> long before anything had a chance to sync. So after flashing a new image,
> **reboot twice**. When verifying a kernel-level change, always confirm what you
> are actually running first:
>
> ```bash
> uname -a          # check the build timestamp, not just the version
> ```

## What the first run installs

`switch-to-emuelec.sh` does the following the first time, so you normally never
have to do any of it by hand:

1. Installs [`emuelec-chainload-sync.sh`](rk-dualboot/emuelec-chainload-sync.sh)
   to `/usr/local/sbin/` and enables
   [`emuelec-chainload-sync.service`](rk-dualboot/emuelec-chainload-sync.service).
2. Inserts [`boot-emuelec-block.txt`](rk-dualboot/boot-emuelec-block.txt)
   **before** the first `setenv load_addr` line in `/boot/boot.cmd` (backing the
   originals up as `*.armbian-orig`) and rebuilds it with
   `mkimage -C none -A arm -T script -n 'flatmax load script' -d /boot/boot.cmd /boot/boot.scr`
   (needs `mkimage`: `apt-get install -y u-boot-tools`).
3. Copies `KERNEL` + the dtb from the USB EmuELEC partition to
   `<emmc-boot>/emuelec/`.

Where the names come from: `DISTRO_BOOTLABEL="EMUELEC"` and
`DISTRO_DISKLABEL="STORAGE"` in `distributions/EmuELEC/options`;
`KERNEL_NAME="KERNEL"` in `config/options`.

> **Upgrading from an older install**: earlier versions put the dtb on eMMC
> under its model-specific filename and referenced that name in `boot.cmd`.
> `switch-to-emuelec.sh` detects such a block, restores the pristine
> `boot.cmd.armbian-orig`, reinstalls the current block and removes the stale
> dtb copies — no manual editing needed, as long as the `*.armbian-orig` backups
> are still present.

## Adapting to another board

The scripts detect everything they need at runtime, so in the normal case there
is nothing to edit. Two knobs exist for the exceptions:

| Setting | Where | When you need it |
|---------|-------|------------------|
| `EMMC_BOOT_DEV` | environment, default `/dev/mmcblk0p1` | the eMMC boot partition is not the first partition of `mmcblk0` |
| `DTB_NAME` | environment | the image ships **more than one** dtb, so the right one cannot be inferred. With a single dtb it is picked automatically; with several the sync refuses to guess and lists the candidates |

The one genuinely board-specific line is the serial console in
`boot-emuelec-block.txt`:

```
setenv bootargs "boot=LABEL=EMUELEC disk=LABEL=STORAGE quiet console=ttyS2,1500000 console=tty0"
```

`ttyS2` is the RK3566 debug UART. Adjust it for boards that use a different one.
The load addresses (`0x02080000` / `0x08300000`) are generic for 64-bit Rockchip
parts and have not needed changing.

## Recovery

- **While Armbian still boots**: `rm /boot/emuelec/TRIGGER`, or restore the
  backups:
  ```bash
  cp /boot/boot.cmd.armbian-orig /boot/boot.cmd && cp /boot/boot.scr.armbian-orig /boot/boot.scr
  ```
- **When EmuELEC will not boot (black screen, no network)**: pulling the USB
  stick will **not** help (see the warning above). In increasing order of effort:
  1. Boot from a **bootable Armbian SD card**, mount the eMMC boot partition,
     delete `emuelec/TRIGGER` or restore the `*.armbian-orig` files. (u-boot
     generally prefers SD over eMMC. Not verified on this board — recommended,
     not guaranteed.)
  2. **MASKROM reflash of Armbian.** Always works: the bootloader, the partition
     table and the reserved areas are never touched by any of this.
- **Dropping the USB stick entirely**: use `installtoemmc` to install EmuELEC
  onto eMMC as a single-boot system. That wipes the Armbian rootfs but keeps
  u-boot and the BOOT partition as the chainload host and as the MASKROM
  recovery path. See [docs/emmc-install.md](emmc-install.md).
