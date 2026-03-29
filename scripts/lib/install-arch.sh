#!/bin/bash
# Install pre-built Liquorix packages on Arch Linux.
# Sourced by install.sh — do not execute directly.

install_arch() {
    local arch=$1

    if [[ "$arch" != "x86_64" ]]; then
        log ERROR "Pre-built Liquorix packages are only available for x86_64 on Arch."
        log WARN  "To run on $arch, build from source: sudo ./scripts/build.sh"
        exit 1
    fi

    local gpg_key='9AE4078033F8024D'
    pacman-key --keyserver hkps://keyserver.ubuntu.com --recv-keys "$gpg_key"
    pacman-key --lsign-key "$gpg_key"
    log INFO "Liquorix signing key added to pacman keyring"

    local repo_file='/etc/pacman.conf'
    if ! grep -q 'liquorix.net/archlinux' "$repo_file"; then
        # shellcheck disable=SC2016
        printf '\n[liquorix]\nServer = https://liquorix.net/archlinux/$repo/$arch\n' \
            | tee -a "$repo_file"
        log INFO "Liquorix repository added to $repo_file"
    else
        log INFO "Liquorix repository already present in $repo_file"
    fi

    if pacman -Q linux-lqx &>/dev/null; then
        log INFO "Liquorix kernel already installed"
    else
        pacman -Sy --noconfirm linux-lqx linux-lqx-headers
        log INFO "Liquorix kernel installed"
    fi

    # Update GRUB if present
    local grub_cfg='/boot/grub/grub.cfg'
    if [[ -f "$grub_cfg" ]]; then
        if grub-mkconfig -o "$grub_cfg"; then
            log INFO "GRUB updated"
        else
            log WARN "GRUB update failed — update bootloader manually"
        fi
    fi
}
