#!/bin/bash
# Distro and architecture detection helpers. Source this file; do not execute directly.

# detect_arch prints the normalized kernel architecture string:
#   x86_64 | arm64 | riscv64
detect_arch() {
    local machine
    machine=$(uname -m)
    case "$machine" in
        x86_64)          echo "x86_64" ;;
        aarch64|arm64)   echo "arm64" ;;
        riscv64)         echo "riscv64" ;;
        *)
            echo "unknown"
            return 1
            ;;
    esac
}

# detect_distro prints a normalized distro token:
#   debian | ubuntu | arch | gentoo | fedora | unknown
detect_distro() {
    local dists=""

    # Pull IDs from os-release (ID and ID_LIKE)
    if [[ -f /etc/os-release ]]; then
        dists=$(grep -P '^ID.*=' /etc/os-release \
            | cut -f2 -d= \
            | tr '\n' ' ' \
            | tr '[:upper:]' '[:lower:]' \
            | tr -dc '[:lower:] [:space:]')
    fi

    # Append landmarks from package managers
    command -v apt-get  &>/dev/null && dists="$dists debian"
    command -v pacman   &>/dev/null && dists="$dists arch"
    command -v emerge   &>/dev/null && dists="$dists gentoo"
    command -v dnf      &>/dev/null && dists="$dists fedora"
    command -v rpm      &>/dev/null && dists="$dists fedora"

    # Deduplicate
    dists=$(echo "$dists" | tr '[:space:]' '\n' | sort -u | xargs)

    # Resolve in priority order (most specific first)
    case "$dists" in
        *gentoo*)  echo "gentoo"  ;;
        *arch*)    echo "arch"    ;;
        *ubuntu*)  echo "ubuntu"  ;;
        *debian*)  echo "debian"  ;;
        *fedora*)  echo "fedora"  ;;
        *)         echo "unknown" ;;
    esac
}
