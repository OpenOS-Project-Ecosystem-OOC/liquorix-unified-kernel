#!/bin/bash
# Build Liquorix RPM packages for Fedora via Docker.
# Sourced by build.sh — do not execute directly.
#
# Requires: Docker

build_rpm() {
    local procs=$1
    local build_num=$2

    log INFO "Building Fedora RPM (jobs=${procs}, build=${build_num})"

    local image="liquorix-build-fedora"
    local out_dir="${REPO_ROOT}/artifacts/fedora"
    mkdir -p "$out_dir"

    if ! docker image inspect "$image" &>/dev/null; then
        log INFO "Bootstrapping Docker image ${image}"
        docker build \
            -t "$image" \
            "${REPO_ROOT}/packaging/fedora"
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="$ARCH" \
        "$image" \
        /build/packaging/fedora/build-inside.sh

    log INFO "RPMs written to ${out_dir}"
}
