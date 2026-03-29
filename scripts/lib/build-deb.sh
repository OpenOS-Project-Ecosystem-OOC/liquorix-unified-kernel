#!/bin/bash
# Build Liquorix .deb packages via Docker.
# Sourced by build.sh — do not execute directly.
#
# Mirrors the approach in damentz/liquorix-package scripts/debian/.
# Requires: Docker

build_deb() {
    local distro=$1   # debian | ubuntu
    local release=$2  # trixie | noble | etc.
    local procs=$3
    local build_num=$4

    log INFO "Building .deb for ${distro}/${release} (jobs=${procs}, build=${build_num})"

    local image="liquorix-build-${distro}-${release}"
    local pkg_dir="${REPO_ROOT}/packaging/debian"
    local out_dir="${REPO_ROOT}/artifacts/debian/${release}"
    mkdir -p "$out_dir"

    # Bootstrap image if not present
    if ! docker image inspect "$image" &>/dev/null; then
        log INFO "Bootstrapping Docker image ${image}"
        docker build \
            --build-arg DISTRO="$distro" \
            --build-arg RELEASE="$release" \
            -t "$image" \
            "${REPO_ROOT}/packaging/debian"
    fi

    docker run --rm \
        -v "${REPO_ROOT}:/build:ro" \
        -v "${out_dir}:/artifacts" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        -e ARCH="$ARCH" \
        "$image" \
        /build/packaging/debian/build-inside.sh

    log INFO "Packages written to ${out_dir}"
}
