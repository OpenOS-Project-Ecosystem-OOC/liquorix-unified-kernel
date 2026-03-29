#!/bin/bash
# Runs inside the openSUSE build container.
# Reuses the Fedora RPM spec with openSUSE-compatible dist tag.
# Mounts: /build = our repo (ro), /liquorix-package = upstream cache (ro)
set -euo pipefail

SPEC="/build/packaging/fedora/kernel-liquorix.spec"
OUT_DIR="/artifacts"

: "${PROCS:=2}"
: "${BUILD:=1}"
: "${RELEASE:=tumbleweed}"

# Source upstream env.sh to get version_upstream and other variables
# shellcheck source=/dev/null
source /liquorix-package/scripts/fedora/env.sh

: "${version_upstream:?version_upstream not set in upstream env.sh}"

DIST=".opensuse.${RELEASE}"

rpmbuild -bb \
    --define "version_upstream ${version_upstream}" \
    --define "version_build ${BUILD}" \
    --define "fedora_release ${RELEASE}" \
    --define "dist ${DIST}" \
    --define "_smp_mflags -j${PROCS}" \
    "$SPEC"

find ~/rpmbuild/RPMS -name '*.rpm' -exec cp -v {} "${OUT_DIR}/" \;
