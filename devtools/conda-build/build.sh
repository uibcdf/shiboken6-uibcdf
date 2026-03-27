#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "${RECIPE_DIR}/../.." && pwd)"
DEFAULT_SOURCE_SITE_PACKAGES="${REPO_ROOT}/package_boundary/site-packages"
SOURCE_SITE_PACKAGES="${SHIBOKEN6_UIBCDF_SOURCE_PREFIX:-$DEFAULT_SOURCE_SITE_PACKAGES}"
MANIFEST="${REPO_ROOT}/manifests/shiboken6.files.txt"

if [ ! -d "$SOURCE_SITE_PACKAGES" ]; then
    echo "Missing source site-packages: $SOURCE_SITE_PACKAGES" >&2
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "Missing manifest: $MANIFEST" >&2
    exit 1
fi

mkdir -p "$SP_DIR/shiboken6_uibcdf" "$SP_DIR/shiboken6_uibcdf-6.9.2.dist-info"

while IFS= read -r relpath; do
    [ -n "$relpath" ] || continue

    case "$relpath" in
        *__pycache__/*|*.pyc)
            continue
            ;;&
    esac
    src="$SOURCE_SITE_PACKAGES/$relpath"
    rewritten_relpath="${relpath/shiboken6\//shiboken6_uibcdf/}"
    rewritten_relpath="${rewritten_relpath/shiboken6-6.9.2.dist-info/pyside_placeholder}"
    rewritten_relpath="${rewritten_relpath/pyside_placeholder/shiboken6_uibcdf-6.9.2.dist-info}"
    dst="$SP_DIR/$rewritten_relpath"

    if [ ! -e "$src" ]; then
        echo "Missing manifest entry in source environment: $src" >&2
        exit 1
    fi

    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
done < "$MANIFEST"

init_py="$SP_DIR/shiboken6_uibcdf/__init__.py"
if [ -f "$init_py" ]; then
    perl -0pi -e 's/from shiboken6\.Shiboken import \*/from shiboken6_uibcdf.Shiboken import */g' "$init_py"
fi
