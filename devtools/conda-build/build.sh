#!/usr/bin/env bash
set -euo pipefail

SOURCE_SITE_PACKAGES="${SHIBOKEN6_UIBCDF_SOURCE_PREFIX:-/home/diego/Myopt/miniconda3/envs/molsyssuite-qt-spike/lib/python3.13/site-packages}"
REPO_ROOT="$(cd "${RECIPE_DIR}/../.." && pwd)"
MANIFEST="${REPO_ROOT}/manifests/shiboken6.files.txt"

if [ ! -d "$SOURCE_SITE_PACKAGES" ]; then
    echo "Missing source site-packages: $SOURCE_SITE_PACKAGES" >&2
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

mkdir -p "$SP_DIR/shiboken6" "$SP_DIR/shiboken6-6.9.2.dist-info"

while IFS= read -r relpath; do
    [ -n "$relpath" ] || continue

    case "$relpath" in
        *__pycache__/*|*.pyc)
            continue
            ;;&
    esac
    src="$SOURCE_SITE_PACKAGES/$relpath"
    dst="$SP_DIR/$relpath"

    if [ ! -e "$src" ]; then
        echo "Missing manifest entry in source environment: $src" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
done < "$MANIFEST"
