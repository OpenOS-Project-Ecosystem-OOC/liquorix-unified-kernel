#!/bin/bash
# Install Liquorix on RHEL-family distros via GitHub Releases or local RPM.
# Covers: RHEL, AlmaLinux, Rocky Linux, Oracle Linux, CentOS Stream,
#         Nobara, Bazzite, Ultramarine, and any other dnf/rpm-based distro.
# Sourced by install.sh — do not execute directly.

install_rhel() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Liquorix RPM packages are only available for x86_64."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    # Try GitHub Releases first — use Fedora 42 RPM as the closest match
    local release_ver
    release_ver=$(latest_release_version)

    if [[ -n "$release_ver" ]]; then
        local kver="${release_ver#v}"
        local filename="kernel-liquorix-${kver}.fc42.x86_64.rpm"
        local tmp_rpm
        tmp_rpm=$(mktemp /tmp/kernel-liquorix-XXXXXX.rpm)

        if download_release_asset "$filename" "$tmp_rpm"; then
            log INFO "Installing from GitHub Release: ${filename}"
            dnf install -y "$tmp_rpm"
            rm -f "$tmp_rpm"
            log INFO "Liquorix kernel installed"
            return
        fi
        rm -f "$tmp_rpm"
        log WARN "GitHub Release asset not found, falling back to local artifact"
    fi

    # Fall back to locally built RPM
    local rpm_path
    rpm_path=$(find artifacts/fedora artifacts/rhel -name 'kernel-liquorix-*.rpm' \
        ! -name '*.src.rpm' 2>/dev/null | sort -V | tail -n1)

    if [[ -z "$rpm_path" ]]; then
        log ERROR "No RPM found under artifacts/fedora/ or artifacts/rhel/."
        log WARN  "Build first with: make build-fedora"
        exit 1
    fi

    log INFO "Installing local RPM: ${rpm_path}"
    dnf install -y "$rpm_path"
    log INFO "Liquorix kernel installed"
}
