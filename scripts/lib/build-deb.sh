#!/bin/bash
# Build Liquorix .deb packages via Docker.
# Sourced by build.sh — do not execute directly.
#
# The Debian pipeline has two stages:
#   1. Source build  — runs in debian/bookworm, produces .dsc + .orig.tar.xz
#   2. Binary build  — runs in target distro/release, produces .deb files
#
# The upstream container scripts (container_build-source.sh,
# container_build-binary.sh) are tightly coupled to the damentz/liquorix-package
# repo layout. They compute paths relative to their own location and expect:
#   /liquorix-package/linux-liquorix/debian/   (package rules)
#   /liquorix-package/artifacts/               (output dir)
#   /liquorix-package/scripts/debian/lib.sh    (shared helpers)
#
# We therefore mount the upstream cache (fetched by bootstrap.sh) as
# /liquorix-package inside the container, and bind-mount our artifacts dir
# over the upstream cache's artifacts/ so output lands in our tree.
#
# Requires: Docker, upstream cache populated by scripts/bootstrap.sh

build_deb() {
    local distro=$1   # debian | ubuntu
    local release=$2  # trixie | noble | etc.
    local procs=$3
    local build_num=$4

    local docker_arch="amd64"
    [[ "${ARCH:-x86_64}" == "arm64"   ]] && docker_arch="arm64v8"
    [[ "${ARCH:-x86_64}" == "riscv64" ]] && docker_arch="riscv64"

    local source_image="liquorix_amd64/debian/bookworm"
    local binary_image="liquorix_${docker_arch}/${distro}/${release}"

    local artifacts_dir="${REPO_ROOT}/artifacts/debian/${release}"
    local cache_dir="${REPO_ROOT}/.upstream-cache"
    mkdir -p "$artifacts_dir"

    if [[ ! -d "${cache_dir}/.git" ]]; then
        log ERROR "Upstream cache not found at ${cache_dir}. Run: make bootstrap-debian"
        exit 1
    fi

    # ── Stage 1: source build ─────────────────────────────────────────────────

    if ! docker image inspect "$source_image" &>/dev/null; then
        log WARN "Source build image ${source_image} not found. Run: make bootstrap-debian"
        exit 1
    fi

    log INFO "Building source package for ${distro}/${release}"
    # shellcheck disable=SC2046
    docker run --rm \
        --net=host \
        --tmpfs /build:exec \
        --ulimit nofile=524288:524288 \
        $(gpg_docker_flags /root) \
        -v "${cache_dir}:/liquorix-package" \
        -v "${artifacts_dir}:/liquorix-package/artifacts/debian/${release}" \
        -e DISTRO="$distro" \
        -e RELEASE="$release" \
        -e BUILD="$build_num" \
        "$source_image" \
        /liquorix-package/scripts/debian/container_build-source.sh \
            "$distro" "$release" "$build_num"

    log INFO "Source packages written to ${artifacts_dir}"

    # ── Stage 2: binary build ─────────────────────────────────────────────────

    if ! docker image inspect "$binary_image" &>/dev/null; then
        log WARN "Binary build image ${binary_image} not found. Run: make bootstrap-${distro}"
        exit 1
    fi

    log INFO "Building binary packages for ${distro}/${release} (jobs=${procs})"
    # shellcheck disable=SC2046
    docker run --rm \
        --net=host \
        --ulimit nofile=524288:524288 \
        $(gpg_docker_flags /root) \
        -v "${cache_dir}:/liquorix-package" \
        -v "${artifacts_dir}:/liquorix-package/artifacts/debian/${release}" \
        -e PROCS="$procs" \
        -e BUILD="$build_num" \
        "$binary_image" \
        /liquorix-package/scripts/debian/container_build-binary.sh \
            "$docker_arch" "$distro" "$release" "$build_num"

    log INFO "Binary packages written to ${artifacts_dir}"
}
