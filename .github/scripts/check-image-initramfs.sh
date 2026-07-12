#!/bin/bash
# NOTE(w2xg2022): 检查缓存的 install_pkg/linux/.image/Image.lzo(烤好的Android bootimg)
# 里的 initramfs 是否完好——不仅要非空,还必须含 glibc 动态链接器(ld-linux-aarch64.so.1)。
# 云编译反复踩的雪花坑根因=initramfs 里 busybox/init 是动态链接的,而 glibc 的
# makeinstall_init 从 glibc build/ 的 .<target>/elf/ 复制 ld*.so/libc.so,若云端缓存的
# glibc build/ 不完整就复制不到 → initramfs 缺 glibc → busybox exec 失败 → 内核 panic →
# 花屏/雪花(能开机但显示坏)。只看 ramdisk 大小抓不到这个(缺 glibc 的 initramfs 仍有 3MB)。
# 返回 0=完好, 1=损坏(空 或 缺glibc,需要整组 kernel lane 重建)。
set -o pipefail
LZO="$1"
[ -f "$LZO" ] || exit 0   # 没有缓存(全新 build)不判断,交给正常流程

read RS OFF < <(python3 -c "
import struct,sys
d=open('$LZO','rb').read(64)
if d[:8]!=b'ANDROID!':
    print('0 0'); sys.exit()
ks=struct.unpack('<I',d[8:12])[0]
rs=struct.unpack('<I',d[16:20])[0]
pg=struct.unpack('<I',d[36:40])[0] or 2048
off=pg+((ks+pg-1)//pg)*pg
print(rs, off)
")

if [ "${RS:-0}" -lt 500000 ]; then
  echo "initramfs 为空(ramdisk_size=${RS}B)"
  exit 1
fi

# 抽出 ramdisk(zstd 压缩的 cpio),列文件名,确认含动态链接器/libc
if dd if="$LZO" bs=2048 skip=$((OFF/2048)) count=$(((RS+2047)/2048)) 2>/dev/null \
   | zstd -dc 2>/dev/null | cpio -t 2>/dev/null | grep -qE "ld-linux-aarch64\.so|libc\.so\.6"; then
  echo "initramfs 完好(ramdisk_size=${RS}B, 含 glibc)"
  exit 0
else
  echo "initramfs 缺 glibc/ld-linux(ramdisk_size=${RS}B 但无 libc.so.6)——就是花屏/雪花的根源"
  exit 1
fi
