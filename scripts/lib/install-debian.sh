#!/bin/bash
# Install pre-built Liquorix packages on Debian.
# Sourced by install.sh — do not execute directly.

install_debian() {
    local arch=$1

    # Only amd64 pre-built packages exist upstream today.
    # When arm64/riscv64 packages are published, remove this guard.
    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Pre-built Liquorix packages are only available for x86_64 on Debian."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    apt-get update && apt-get install -y --no-install-recommends \
        curl gpg ca-certificates

    mkdir -p /etc/apt/{sources.list.d,keyrings}
    chmod 0755 /etc/apt/{sources.list.d,keyrings}

    local keyring_url='https://liquorix.net/liquorix-keyring.gpg'
    local keyring_path='/etc/apt/keyrings/liquorix-keyring.gpg'
    curl "$keyring_url" | gpg --batch --yes --output "$keyring_path" --dearmor
    chmod 0644 "$keyring_path"
    log INFO "Liquorix keyring installed at $keyring_path"

    apt-get install -y apt-transport-https lsb-release

    local repo_file="/etc/apt/sources.list.d/liquorix.list"
    local repo_code
    repo_code=$(apt-cache policy \
        | grep 'o=Debian' \
        | grep -Po 'n=\w+' \
        | cut -f2 -d= \
        | sort | uniq -c | sort | tail -n1 | awk '{print $2}')

    local repo_line="[arch=amd64 signed-by=${keyring_path}] https://liquorix.net/debian ${repo_code} main"
    echo "deb ${repo_line}"     >  "$repo_file"
    echo "deb-src ${repo_line}" >> "$repo_file"
    apt-get update -y
    log INFO "Liquorix repository configured at $repo_file"

    apt-get install -y linux-image-liquorix-amd64 linux-headers-liquorix-amd64
    log INFO "Liquorix kernel installed"
}
