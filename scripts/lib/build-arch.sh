#!/bin/bash
# Build Liquorix .pkg.tar.zst for Arch Linux via Docker.
# Sourced by build.sh — do not execute directly.
#
# Requires: Docker

build_arch() {
    local procs=$1

    log INFO "Building Arch Linux package (jobs=${procs})"

    local image="liquorix-build-archlinux"
    local out_dir="${REPO_ROOT}/artifacts/arch"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log INFO "Bootstrapping Docker image ${image}"
        docker build \
            -t "$image" \
            "${REPO_ROOT}/packaging/arch"
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e ARCH="$ARCH" \
        "$image" \
        /build/packaging/arch/build-inside.sh

    log INFO "Package written to ${out_dir}"
}
