#!/bin/bash
# Install pre-built Liquorix packages on Ubuntu via PPA.
# Sourced by install.sh — do not execute directly.

install_ubuntu() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Pre-built Liquorix packages are only available for x86_64 on Ubuntu."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    apt-get update && apt-get install -y --no-install-recommends \
        gpg gpg-agent software-properties-common

    add-apt-repository -y ppa:damentz/liquorix
    apt-get update -y
    log INFO "Liquorix PPA configured"

    apt-get install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64
    log INFO "Liquorix kernel installed"
}
