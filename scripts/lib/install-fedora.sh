#!/bin/bash
# Install Liquorix on Fedora/RHEL via COPR or local RPM.
# Sourced by install.sh — do not execute directly.
#
# NOTE: No official Liquorix COPR exists yet. This installs from a locally
# built RPM produced by `make build-binary-fedora`. When an official COPR
# is published, replace the local-install path with a `dnf copr enable` call.

install_fedora() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Liquorix RPM packages are only available for x86_64."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    # Look for a locally built RPM in the artifacts directory
    local rpm_path
    rpm_path=$(find artifacts/fedora -name 'kernel-liquorix-*.rpm' \
        ! -name '*.src.rpm' 2>/dev/null | sort -V | tail -n1)

    if [[ -z "$rpm_path" ]]; then
        log ERROR "No Fedora RPM found under artifacts/fedora/."
        log WARN  "Build first with: make build-binary-fedora"
        exit 1
    fi

    log INFO "Installing $rpm_path"
    dnf install -y "$rpm_path"
    log INFO "Liquorix kernel installed"
}
