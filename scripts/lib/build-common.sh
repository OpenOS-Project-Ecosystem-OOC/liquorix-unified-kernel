#!/bin/bash
# Shared build helpers. Source this file; do not execute directly.

# fetch_sources downloads the vanilla kernel tarball and the liquorix-package
# archive into $SRCDIR, then extracts them.
#
# Globals used: KERNEL_VERSION, KERNEL_MAJOR, LQX_REL, SRCDIR
fetch_sources() {
    mkdir -p "$SRCDIR"

    local kernel_tar="${SRCDIR}/linux-${KERNEL_MAJOR}.tar.xz"
    local lqx_tar="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}.tar.gz"

    if [[ ! -f "$kernel_tar" ]]; then
        log INFO "Downloading linux-${KERNEL_MAJOR}.tar.xz"
        curl -L --fail \
            "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR%%.*}.x/linux-${KERNEL_MAJOR}.tar.xz" \
            -o "$kernel_tar"
    fi

    if [[ ! -f "$lqx_tar" ]]; then
        log INFO "Downloading liquorix-package-${KERNEL_MAJOR}-${LQX_REL}.tar.gz"
        curl -L --fail \
            "https://github.com/damentz/liquorix-package/archive/${KERNEL_MAJOR}-${LQX_REL}.tar.gz" \
            -o "$lqx_tar"
    fi

    log INFO "Extracting sources"
    tar -xf "$kernel_tar" -C "$SRCDIR"
    tar -xf "$lqx_tar"   -C "$SRCDIR"
}

# apply_patches applies the zen/lqx patch series from the liquorix-package
# archive onto the extracted kernel source tree.
#
# Globals used: KERNEL_MAJOR, LQX_REL, SRCDIR
apply_patches() {
    local patch_dir="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}/linux-liquorix/debian/patches"
    local kernel_dir="${SRCDIR}/linux-${KERNEL_MAJOR}"

    log INFO "Applying Liquorix patch series"
    grep -P '^(zen|lqx)/' "${patch_dir}/series" | while IFS= read -r patch; do
        log INFO "  patch: $patch"
        patch -Np1 -d "$kernel_dir" -i "${patch_dir}/${patch}"
    done
}

# select_config copies the appropriate Liquorix kernel config for the target
# architecture into the kernel source tree as .config.
#
# Globals used: ARCH, KERNEL_MAJOR, LQX_REL, SRCDIR, REPO_ROOT
select_config() {
    local kernel_dir="${SRCDIR}/linux-${KERNEL_MAJOR}"
    local lqx_pkg_dir="${SRCDIR}/liquorix-package-${KERNEL_MAJOR}-${LQX_REL}"

    local config_src
    case "$ARCH" in
        x86_64)
            # Upstream config from damentz/liquorix-package
            config_src="${lqx_pkg_dir}/linux-liquorix/debian/config/kernelarch-x86/config-arch-64"
            ;;
        arm64|riscv64)
            # Local config authored in this repo (see configs/<arch>/config)
            config_src="${REPO_ROOT}/configs/${ARCH}/config"
            if [[ ! -f "$config_src" ]]; then
                log ERROR "No config found for ${ARCH} at ${config_src}"
                log WARN  "See docs/adding-arch.md to author a new architecture config"
                exit 1
            fi
            ;;
        *)
            log ERROR "Unsupported architecture: ${ARCH}"
            exit 1
            ;;
    esac

    log INFO "Using config: $config_src"
    cp "$config_src" "${kernel_dir}/.config"
}
