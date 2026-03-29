# Liquorix Unified

A single build and install system for the [Liquorix kernel](https://liquorix.net)
across all major Linux distributions and CPU architectures.

Liquorix is a Linux kernel built with the Zen patch set and tuned for desktop
responsiveness and low latency. This repo unifies the previously fragmented
packaging efforts into one place.

## Supported distros

| Distro | Install method | Build method |
|---|---|---|
| Debian | Pre-built `.deb` from liquorix.net | Docker + `dpkg-buildpackage` |
| Ubuntu | Pre-built `.deb` via PPA | Docker + `dpkg-buildpackage` |
| Arch Linux | Pre-built package from liquorix.net | Docker + `makepkg` |
| Fedora | Local RPM (no COPR yet) | Docker + `rpmbuild` |
| Gentoo | Source build via `genkernel` | `genkernel` on-host |

## Supported architectures

| Architecture | Status |
|---|---|
| x86_64 | ✅ Full support — pre-built packages available |
| arm64 | 🔧 Build system ready — kernel config not yet authored |
| riscv64 | 🔧 Build system ready — kernel config not yet authored |

To contribute an arm64 or riscv64 config, see [docs/adding-arch.md](docs/adding-arch.md).

## Quick install

Detects your distro and installs the appropriate pre-built package:

```bash
sudo ./scripts/install.sh
```

On Gentoo, set `KERNEL_VERSION` first:

```bash
KERNEL_VERSION=6.12.1 sudo ./scripts/install.sh
```

## Building from source

Requires Docker (except Gentoo).

```bash
# Debian
make build-debian RELEASE=trixie

# Ubuntu
make build-ubuntu RELEASE=noble

# Arch Linux
make build-arch

# Fedora
make build-fedora

# Gentoo (no Docker — runs genkernel on the host)
make build-gentoo KERNEL_VERSION=6.12.1
```

Run `make` with no arguments to see all targets and variables.

## Repository layout

```
configs/            Kernel .config files per architecture
  x86_64/           Pulled from damentz/liquorix-package at build time
  arm64/            Placeholder — see docs/adding-arch.md
  riscv64/          Placeholder — see docs/adding-arch.md

packaging/          Distro-specific packaging metadata
  debian/           Debian/Ubuntu package rules (Dockerfiles + build scripts)
  arch/             Arch Linux PKGBUILD (Dockerfile + build script)
  fedora/           Fedora RPM spec (Dockerfile + build script)
  gentoo/           Gentoo ebuild helpers

scripts/
  install.sh        Unified installer entry point
  build.sh          Unified build entry point
  lib/
    log.sh          Logging helpers
    detect.sh       Distro and architecture detection
    install-*.sh    Per-distro install logic
    build-*.sh      Per-distro build logic

docs/
  adding-arch.md    How to author a kernel config for a new architecture

.github/workflows/
  build.yml         CI matrix: distros × architectures
```

## Relationship to upstream projects

This repo consolidates:

| Source | Contribution absorbed |
|---|---|
| [damentz/liquorix-package](https://github.com/damentz/liquorix-package) | Canonical upstream — patches, configs, Debian/Arch/Fedora build system |
| [archdevlab/linux-lqx](https://github.com/archdevlab/linux-lqx) | Arch PKGBUILD approach |
| [MartinAlejandroOviedo/liquorix4all](https://github.com/MartinAlejandroOviedo/liquorix4all) | Debian installer pattern |
| [GKernelCI/gentoo-sources-build](https://github.com/GKernelCI/gentoo-sources-build) | Gentoo genkernel build approach |

Patches and kernel configs continue to originate from
[damentz/liquorix-package](https://github.com/damentz/liquorix-package) and
the [zen-kernel](https://github.com/zen-kernel/zen-kernel). This repo does not
fork the kernel itself.

## License

GPL-2.0 — same as the Linux kernel.
