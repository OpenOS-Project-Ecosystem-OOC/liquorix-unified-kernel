#!/bin/bash
# Build Liquorix directly on a Gentoo host (no Docker — genkernel manages the build).
# Sourced by build.sh — do not execute directly.
#
# Requires: gentoo-sources, genkernel, wget
# Globals used: KERNEL_VERSION, ARCH, REPO_ROOT

build_gentoo() {
    local procs=$1

    if [[ -z "${KERNEL_VERSION:-}" ]]; then
        log ERROR "KERNEL_VERSION must be set (e.g. KERNEL_VERSION=6.12.1 make build-gentoo)"
        exit 1
    fi

    local kernel_major="${KERNEL_VERSION%.*}"

    local config_src
    case "$ARCH" in
        x86_64)
            config_src="https://raw.githubusercontent.com/damentz/liquorix-package/${kernel_major}/master/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
            ;;
        arm64|riscv64)
            local local_cfg="${REPO_ROOT}/configs/${ARCH}/config"
            if [[ ! -f "$local_cfg" ]]; then
                log ERROR "No config for ${ARCH} at ${local_cfg}"
                log WARN  "See docs/adding-arch.md"
                exit 1
            fi
            config_src="file://${local_cfg}"
            ;;
        *)
            log ERROR "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    local tmp_conf
    tmp_conf=$(mktemp "/tmp/lqx-config-${KERNEL_VERSION}.XXXXXXXXXX")

    log INFO "Fetching Liquorix config"
    wget -q "$config_src" -O "$tmp_conf"

    # Gentoo-specific adjustments
    sed -i \
        -e 's/CONFIG_CRYPTO_CRC32C=m/CONFIG_CRYPTO_CRC32C=y/' \
        -e 's/CONFIG_FW_LOADER_USER_HELPER=y/CONFIG_FW_LOADER_USER_HELPER=n/' \
        -e 's/CONFIG_ISO9660_FS=m/CONFIG_ISO9660_FS=y/' \
        "$tmp_conf"

    log INFO "Building kernel ${KERNEL_VERSION}-gentoo (jobs=${procs})"
    genkernel \
        --makeopts="-j${procs}" \
        --kernel-ld=ld.bfd \
        --kernel-config="$tmp_conf" \
        --luks \
        --lvm \
        all

    rm -f "$tmp_conf"
    log INFO "Gentoo kernel build complete"
}
