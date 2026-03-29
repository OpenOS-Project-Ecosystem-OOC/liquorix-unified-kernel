#!/bin/bash
# Build Liquorix RPM packages for Fedora via Docker.
# Sourced by build.sh — do not execute directly.
#
# The Fedora container_build-binary.sh also expects the damentz repo layout.
# We mount the upstream cache and bind-mount our artifacts dir over it.
#
# Requires: Docker, upstream cache populated by scripts/bootstrap.sh

build_rpm() {
    local procs=$1
    local build_num=$2

    local fedora_release="${FEDORA_RELEASE:-42}"
    local image="liquorix_amd64/fedora/${fedora_release}"
    local out_dir="${REPO_ROOT}/artifacts/fedora"
    local cache_dir="${REPO_ROOT}/.upstream-cache"
    mkdir -p "$out_dir"

    if [[ ! -d "${cache_dir}/.git" ]]; then
        log ERROR "Upstream cache not found at ${cache_dir}. Run: make bootstrap-fedora"
        exit 1
    fi

    if ! docker image inspect "$image" &>/dev/null; then
        log WARN "Docker image ${image} not found. Run: make bootstrap-fedora"
        exit 1
    fi

    log INFO "Building Fedora RPM (release=${fedora_release}, jobs=${procs})"
    # shellcheck disable=SC2046
    docker run --rm \
        --net=host \
        --ulimit nofile=524288:524288 \
        $(gpg_docker_flags /home/builder) \
        -v "${cache_dir}:/liquorix-package:ro" \
        -v "${out_dir}:/liquorix-package/artifacts/fedora/${fedora_release}" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        "$image" \
        /liquorix-package/scripts/fedora/container_build-binary.sh \
            "amd64" "fedora" "$fedora_release" "$build_num"

    log INFO "RPMs written to ${out_dir}"
}
