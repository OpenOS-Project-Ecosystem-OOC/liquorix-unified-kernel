#!/bin/bash
# Build and install Liquorix on Gentoo using genkernel + liquorix config.
# Sourced by install.sh — do not execute directly.
#
# Requires: gentoo-sources, genkernel, wget

install_gentoo() {
    local arch=$1
    local kernel_version=${KERNEL_VERSION:-}

    if [[ -z "$kernel_version" ]]; then
        log ERROR "KERNEL_VERSION must be set (e.g. KERNEL_VERSION=6.12.1 sudo ./scripts/install.sh)"
        exit 1
    fi

    # Derive major version (e.g. 6.12.1 -> 6.12)
    local kernel_major="${kernel_version%.*}"

    # Only x86_64 has an upstream Liquorix config today.
    # arm64/riscv64 configs live in configs/<arch>/config once authored.
    local config_url
    case "$arch" in
        x86_64)
            config_url="https://raw.githubusercontent.com/damentz/liquorix-package/${kernel_major}/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
            ;;
        arm64|riscv64)
            # Fall back to the local config authored in this repo
            local local_config
            local_config="$(dirname "$(realpath "$0")")/../../configs/${arch}/config"
            if [[ ! -f "$local_config" ]]; then
                log ERROR "No Liquorix config found for $arch at $local_config"
                log WARN  "See docs/adding-arch.md to author a new architecture config"
                exit 1
            fi
            config_url="file://${local_config}"
            ;;
        *)
            log ERROR "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    # Remove old gentoo-sources to avoid slot conflicts
    log INFO "Removing old gentoo-sources"
    emerge -C gentoo-sources 2>/dev/null || true
    find /usr/src/ /boot/ /lib/modules/ \
        -mindepth 1 -maxdepth 1 \
        -name "*gentoo*" \
        ! -name "*$(uname -r)" \
        -exec rm -rf {} + 2>/dev/null || true

    # Install target version
    log INFO "Installing gentoo-sources-${kernel_version}"
    emerge --sync
    emerge -b "=gentoo-sources-${kernel_version}" --nodeps
    eselect kernel set "linux-${kernel_version}-gentoo"

    # Download Liquorix config
    local tmp_conf
    tmp_conf=$(mktemp "/tmp/lqx-config-${kernel_version}.XXXXXXXXXX")
    log INFO "Fetching Liquorix config from ${config_url}"
    wget -q "$config_url" -O "$tmp_conf"

    # Gentoo-specific config adjustments (from GKernelCI/gentoo-sources-build)
    sed -i \
        -e 's/CONFIG_CRYPTO_CRC32C=m/CONFIG_CRYPTO_CRC32C=y/' \
        -e 's/CONFIG_FW_LOADER_USER_HELPER=y/CONFIG_FW_LOADER_USER_HELPER=n/' \
        -e 's/CONFIG_ISO9660_FS=m/CONFIG_ISO9660_FS=y/' \
        "$tmp_conf"

    # Build
    log INFO "Building kernel ${kernel_version}-gentoo with genkernel"
    genkernel \
        --kernel-ld=ld.bfd \
        --kernel-config="$tmp_conf" \
        --luks \
        --lvm \
        all

    # Rebuild external modules
    cd "/usr/src/linux-${kernel_version}-gentoo"
    make LD=ld.bfd prepare
    make LD=ld.bfd modules_prepare
    emerge -b @module-rebuild

    rm -f "$tmp_conf"
    log INFO "Liquorix kernel ${kernel_version} installed on Gentoo"
}
