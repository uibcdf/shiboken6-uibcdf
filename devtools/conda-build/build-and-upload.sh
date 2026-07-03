#!/usr/bin/env bash
#
# build-and-upload.sh — build this package and upload it to the uibcdf conda
# channel (anaconda.org/uibcdf), so users can install it with:
#     mamba install -c uibcdf -c conda-forge <package>
#
# The upstream version stays FIXED (6.9.2). "Newer" is signalled by the recipe's
# build number (build: number in meta.yaml) — bump it before re-uploading.
#
# Run the family in order (each repo has its own build-and-upload.sh):
#     1. shiboken6-uibcdf           <-- this repo
#     2. pyside6-essentials-uibcdf
#     3. qt6-positioning-uibcdf     (repackage: needs QT6_*_SOURCE_*)
#     4. qt6-webengine-uibcdf       (repackage: needs QT6_*_SOURCE_*)
#     5. pyside6-addons-uibcdf
#
# Auth: run `anaconda login` first, or export ANACONDA_API_TOKEN.
#
# Usage:
#     conda activate <build-env>
#     ./devtools/conda-build/build-and-upload.sh
#
set -euo pipefail

PKG_NAME="shiboken6-uibcdf"
CHANNEL="uibcdf"
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIRED_PKGS=()

if ! conda build --version >/dev/null 2>&1; then
    echo "error: 'conda build' not available.  mamba install -n base conda-build" >&2
    exit 1
fi
if ! command -v anaconda >/dev/null 2>&1; then
    echo "error: 'anaconda' (anaconda-client) not available.  mamba install -n base anaconda-client" >&2
    exit 1
fi
if [ -z "${CONDA_PREFIX:-}" ]; then
    echo "error: no active conda environment (activate the build env first)." >&2
    exit 1
fi

# Resolve the output artifact path (does not build) + the local conda-bld dir.
OUT="$(conda build "${RECIPE_DIR}" -c local -c conda-forge --output 2>/dev/null | grep -E '\.(conda|tar\.bz2)$' | tail -1)"
if [ -z "${OUT}" ]; then
    echo "error: could not resolve the build output path (conda build --output)." >&2
    exit 1
fi
CB_DIR="$(dirname "${OUT}")"

# Prerequisite uibcdf packages must already be built into the local channel.
for dep in "${REQUIRED_PKGS[@]}"; do
    ls "${CB_DIR}/${dep}-6.9.2-"*.conda >/dev/null 2>&1 || {
        echo "error: prerequisite '${dep}' not found in local conda-bld (${CB_DIR})." >&2
        echo "       build it FIRST via its build-and-upload.sh (family order)." >&2
        exit 1
    }
done

echo ">> [${PKG_NAME}] building ..."
conda build "${RECIPE_DIR}" -c local -c conda-forge

ANACONDA=(anaconda)
[ -n "${ANACONDA_API_TOKEN:-}" ] && ANACONDA+=(-t "${ANACONDA_API_TOKEN}")
echo ">> [${PKG_NAME}] uploading ${OUT} to channel '${CHANNEL}' ..."
"${ANACONDA[@]}" upload -u "${CHANNEL}" "${OUT}"

echo ">> [${PKG_NAME}] done. Install with: mamba install -c ${CHANNEL} -c conda-forge ${PKG_NAME}"
