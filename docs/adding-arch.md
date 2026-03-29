# Adding a new architecture

This document describes how to author a Liquorix kernel config for an
architecture that does not yet have one (e.g. arm64, riscv64).

## Prerequisites

- A machine or QEMU environment running the target architecture
- The kernel source for the version you are targeting
- Familiarity with `make menuconfig` / `make nconfig`

## Steps

### 1. Start from the upstream defconfig

```bash
KERNEL_VERSION=6.12.1
ARCH=arm64   # or riscv64

wget "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION%.*}.tar.xz"
tar -xf linux-${KERNEL_VERSION%.*}.tar.xz
cd linux-${KERNEL_VERSION%.*}

make ARCH=$ARCH defconfig
```

### 2. Apply Liquorix tuning

The following settings reflect the Liquorix philosophy. Apply them with
`scripts/config` after `defconfig`:

```bash
# Scheduler — use BORE (if available) or CFS with low latency
scripts/config --enable  CONFIG_SCHED_BORE        # BORE scheduler
scripts/config --disable CONFIG_SCHED_ALT
scripts/config --disable CONFIG_PDS
scripts/config --disable CONFIG_BMQ

# Preemption — full preemption for desktop responsiveness
scripts/config --enable  CONFIG_PREEMPT
scripts/config --disable CONFIG_PREEMPT_VOLUNTARY
scripts/config --disable CONFIG_PREEMPT_NONE

# Timer frequency — 1000 Hz for low latency
scripts/config --enable  CONFIG_HZ_1000
scripts/config --disable CONFIG_HZ_250
scripts/config --set-val CONFIG_HZ 1000

# MQ deadline I/O scheduler as default
scripts/config --enable  CONFIG_MQ_IOSCHED_DEADLINE
scripts/config --enable  CONFIG_MQ_IOSCHED_KYBER

# Disable mitigations that hurt desktop performance (optional, security trade-off)
# scripts/config --disable CONFIG_SPECULATION_MITIGATIONS

# Zswap / ZRAM
scripts/config --enable CONFIG_ZSWAP
scripts/config --enable CONFIG_ZRAM

# Futex — needed for gaming/Wine
scripts/config --enable CONFIG_FUTEX
scripts/config --enable CONFIG_FUTEX_PI
```

### 3. Resolve dependencies

```bash
make ARCH=$ARCH olddefconfig
```

### 4. Review and refine interactively

```bash
make ARCH=$ARCH nconfig
```

Pay attention to:
- `Processor type and features` — match the target hardware class
- `Power management` — cpufreq governors, energy-aware scheduling
- `Networking` — BBR, cake, fq_codel
- `File systems` — enable common ones as built-in, not modules

### 5. Test build

```bash
make ARCH=$ARCH -j$(nproc) Image modules
```

Fix any config errors that surface.

### 6. Place the config

Copy the finished `.config` to this repo:

```bash
cp .config /path/to/liquorix-unified/configs/<arch>/config
```

### 7. Open a pull request

Include in the PR description:
- Hardware or QEMU environment used for testing
- Kernel version tested against
- Any deliberate deviations from the x86_64 Liquorix config and why
