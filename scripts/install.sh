#!/bin/bash
# Liquorix unified installer.
#
# Detects the running distro and architecture, then installs the Liquorix
# kernel using the appropriate method for that environment.
#
# Usage:
#   sudo ./scripts/install.sh
#
# Environment variables:
#   KERNEL_VERSION  Required on Gentoo (e.g. KERNEL_VERSION=6.12.1)
#
# Supported distros:  Debian, Ubuntu, Arch Linux, Gentoo, Fedora
# Supported arches:   x86_64 (pre-built); arm64, riscv64 (build from source)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=lib/detect.sh
source "${SCRIPT_DIR}/lib/detect.sh"
# shellcheck source=lib/install-debian.sh
source "${SCRIPT_DIR}/lib/install-debian.sh"
# shellcheck source=lib/install-ubuntu.sh
source "${SCRIPT_DIR}/lib/install-ubuntu.sh"
# shellcheck source=lib/install-arch.sh
source "${SCRIPT_DIR}/lib/install-arch.sh"
# shellcheck source=lib/install-fedora.sh
source "${SCRIPT_DIR}/lib/install-fedora.sh"
# shellcheck source=lib/install-gentoo.sh
source "${SCRIPT_DIR}/lib/install-gentoo.sh"

# ── Guards ────────────────────────────────────────────────────────────────────

if [[ "$(id -u)" -ne 0 ]]; then
    log ERROR "This script must be run as root."
    exit 1
fi

# ── Detection ─────────────────────────────────────────────────────────────────

ARCH=$(detect_arch) || {
    log ERROR "Unsupported architecture: $(uname -m)"
    exit 1
}

DISTRO=$(detect_distro)

log INFO "Detected distro : ${DISTRO}"
log INFO "Detected arch   : ${ARCH}"

# ── Dispatch ──────────────────────────────────────────────────────────────────

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_SUSPEND='*'

case "$DISTRO" in
    debian)  install_debian  "$ARCH" ;;
    ubuntu)  install_ubuntu  "$ARCH" ;;
    arch)    install_arch    "$ARCH" ;;
    gentoo)  install_gentoo  "$ARCH" ;;
    fedora)  install_fedora  "$ARCH" ;;
    *)
        log ERROR "Unsupported distribution: ${DISTRO}"
        log WARN  "Supported: Debian, Ubuntu, Arch Linux, Gentoo, Fedora"
        exit 1
        ;;
esac
