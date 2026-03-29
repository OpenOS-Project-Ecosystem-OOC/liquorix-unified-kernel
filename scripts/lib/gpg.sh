#!/bin/bash
# GPG signing helpers for the Liquorix build pipeline.
# Source this file; do not execute directly.
#
# Signing is optional for local builds — packages are produced unsigned if
# GPG is unavailable. CI signing requires the following GitHub Actions secrets:
#
#   GPG_PRIVATE_KEY   ASCII-armored private key (gpg --armor --export-secret-keys <id>)
#   GPG_PASSPHRASE    Passphrase for the private key (empty string if none)
#
# The key is imported into a temporary GNUPGHOME at the start of each CI run
# and cleaned up afterwards. See .github/workflows/build.yml for usage.

# gpg_import_ci_key imports the GPG key from environment variables set by CI.
# Call this at the start of a CI job that needs to sign packages.
#
# Env vars: GPG_PRIVATE_KEY, GPG_PASSPHRASE
gpg_import_ci_key() {
    if [[ -z "${GPG_PRIVATE_KEY:-}" ]]; then
        log WARN "GPG_PRIVATE_KEY not set — packages will not be signed"
        return 0
    fi

    export GNUPGHOME
    GNUPGHOME=$(mktemp -d)
    chmod 700 "$GNUPGHOME"

    echo "$GPG_PRIVATE_KEY" \
        | gpg --batch --import --passphrase "${GPG_PASSPHRASE:-}" 2>/dev/null

    # Trust the imported key fully
    local key_id
    key_id=$(gpg --list-secret-keys --with-colons \
        | awk -F: '/^sec/{print $5; exit}')
    echo "${key_id}:6:" | gpg --import-ownertrust

    log INFO "GPG key ${key_id} imported for signing"
}

# gpg_cleanup removes the temporary GNUPGHOME created by gpg_import_ci_key.
gpg_cleanup() {
    if [[ -n "${GNUPGHOME:-}" && -d "$GNUPGHOME" ]]; then
        rm -rf "$GNUPGHOME"
        unset GNUPGHOME
    fi
}

# gpg_docker_flags returns docker run flags to mount the GPG socket and
# keyring into a container, enabling in-container signing via the host agent.
# Returns empty string if GPG is not available.
#
# Usage: docker run $(gpg_docker_flags /home/builder) ...
gpg_docker_flags() {
    local container_home="${1:-/root}"

    command -v gpg &>/dev/null || return 0
    [[ -d "${GNUPGHOME:-$HOME/.gnupg}" ]] || return 0

    local gnupg_dir="${GNUPGHOME:-$HOME/.gnupg}"
    local flags="-v ${gnupg_dir}:${container_home}/.gnupg"

    # Mount the agent socket if available (avoids passphrase prompts)
    local agent_socket
    agent_socket=$(gpgconf --list-dirs agent-socket 2>/dev/null || true)
    if [[ -n "$agent_socket" && -S "$agent_socket" ]]; then
        flags+=" -v ${agent_socket}:${container_home}/.gnupg/S.gpg-agent"
    fi

    echo "$flags"
}
