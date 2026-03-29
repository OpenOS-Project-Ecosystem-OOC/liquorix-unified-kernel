#!/bin/bash
# Helpers for fetching the upstream damentz/liquorix-package repo.
# Source this file; do not execute directly.
#
# The upstream container scripts (container_build-*.sh, env.sh, lib.sh) are
# tightly coupled to the damentz repo layout. Rather than syncing individual
# files into our packaging/ dirs, we clone the full upstream repo into
# .upstream-cache/ and mount it as /liquorix-package inside build containers.
# This gives the container scripts exactly the layout they expect.

UPSTREAM_REPO="https://github.com/damentz/liquorix-package"

# fetch_upstream_scripts clones or updates the upstream repo into
# .upstream-cache/ at the latest kernel branch.
#
# The distro argument is accepted for API compatibility but ignored —
# we always clone the full repo.
fetch_upstream_scripts() {
    local cache_dir="${REPO_ROOT}/.upstream-cache"

    # Resolve the latest kernel branch (e.g. 6.19/master)
    local branch
    branch=$(git ls-remote --heads "$UPSTREAM_REPO" \
        | grep -oP '\d+\.\d+/master' \
        | sort -V \
        | tail -1)

    if [[ -z "$branch" ]]; then
        log ERROR "Could not determine latest branch from ${UPSTREAM_REPO}"
        exit 1
    fi

    if [[ ! -d "${cache_dir}/.git" ]]; then
        log INFO "Cloning damentz/liquorix-package @ ${branch}"
        git clone --depth=1 --branch "$branch" "$UPSTREAM_REPO" "$cache_dir"
    else
        local current_branch
        current_branch=$(git -C "$cache_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
        if [[ "$current_branch" != "$branch" ]]; then
            log INFO "Switching upstream cache from ${current_branch} to ${branch}"
            git -C "$cache_dir" fetch --depth=1 origin "$branch"
            git -C "$cache_dir" checkout FETCH_HEAD
        else
            log INFO "Updating upstream cache (branch ${branch})"
            git -C "$cache_dir" fetch --depth=1 origin "$branch"
            git -C "$cache_dir" reset --hard FETCH_HEAD
        fi
    fi

    log INFO "Upstream cache ready at ${cache_dir} (branch ${branch})"
}
