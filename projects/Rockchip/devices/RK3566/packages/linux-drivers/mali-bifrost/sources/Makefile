# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

# ★这个档不是上游 kbase 的一部分,是建置系统需要的垫片★
# rocknix/mali_kbase 的 tarball【根目录只有 product/】,没有顶层 Makefile,
# 而 package.mk 的 make_target 是 `kernel_make -C ${PKG_BUILD}`,
# 直接跑会得到 "No targets specified and no makefile found. Stop."(2026-08-01 实测)。
# scripts/unpack 会把 ${PKG_DIR}/sources/* 复制进 PKG_BUILD,所以放这里就补上了。
# 原档抄自 ROCKNIX:projects/ROCKNIX/packages/linux-drivers/mali-bifrost/sources/Makefile

export

MALI_KBASE_SRC_DIR = $(CURDIR)/product/kernel/drivers/gpu/arm/midgard

all:
	$(MAKE) -C $(MALI_KBASE_SRC_DIR) all

clean:
	$(MAKE) -C $(MALI_KBASE_SRC_DIR) clean
