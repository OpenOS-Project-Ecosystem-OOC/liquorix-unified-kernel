#!/bin/bash
# Build Liquorix RPM packages for openSUSE via Docker.
# Sourced by build.sh — do not execute directly.
#
# openSUSE uses our own packaging/opensuse/ Dockerfile and build-inside.sh
# (not the upstream damentz scripts) since there is no upstream openSUSE support.
# The upstream cache is still needed for the kernel source and patch series,
# which build-inside.sh fetches from env.sh in the fedora upstream scripts.
#
# Requires: Docker, upstream cache populated by scripts/bootstrap.sh

build_opensuse() {
    local procs=$1
    local build_num=$2

    local opensuse_release="${OPENSUSE_RELEASE:-tumbleweed}"
    local image="liquorix_amd64/opensuse/${opensuse_release}"
    local out_dir="${REPO_ROOT}/artifacts/opensuse"
    local cache_dir="${REPO_ROOT}/.upstream-cache"
    mkdir -p "$out_dir"

    if [[ ! -d "${cache_dir}/.git" ]]; then
        log ERROR "Upstream cache not found. Run: make bootstrap-opensuse"
        exit 1
    fi

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-opensuse"
        exit 1
    fi

    log INFO "Building openSUSE RPM (release=${opensuse_release}, jobs=${procs})"
    docker run --rm \
        --net=host \
        --ulimit nofile=524288:524288 \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${cache_dir}:/liquorix-package:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e RELEASE="$opensuse_release" \
        "$image" \
        /build/packaging/opensuse/build-inside.sh

    log INFO "RPMs written to ${out_dir}"
}
