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
# Options:
#   -j, --jobs N    parallel compile jobs (exported as CPU_COUNT; default: all cores)
#
# Auth: run `anaconda login` first, or export ANACONDA_API_TOKEN.
#
# Usage:
#     conda activate <build-env>
#     ./devtools/conda-build/build-and-upload.sh [-j N]
#
set -euo pipefail

PKG_NAME="shiboken6-uibcdf"
CHANNEL="uibcdf"
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JOBS=""
while [ $# -gt 0 ]; do
    case "$1" in
        -j|--jobs) JOBS="${2:-}"; shift 2 ;;
        -j*)       JOBS="${1#-j}"; shift ;;
        --jobs=*)  JOBS="${1#*=}"; shift ;;
        -h|--help) echo "usage: $0 [-j N]   (N = parallel compile jobs)"; exit 0 ;;
        *) echo "error: unknown argument: $1" >&2; exit 2 ;;
    esac
done
if [ -n "${JOBS}" ]; then
    case "${JOBS}" in ""|*[!0-9]*) echo "error: -j/--jobs needs a positive integer" >&2; exit 2 ;; esac
    export CPU_COUNT="${JOBS}"   # honoured by conda-build and the recipe's cmake --parallel
fi

if ! conda build --version >/dev/null 2>&1; then
    echo "error: 'conda build' not available.  mamba install -n base conda-build" >&2; exit 1
fi
if ! command -v anaconda >/dev/null 2>&1; then
    echo "error: 'anaconda' (anaconda-client) not available.  mamba install -n base anaconda-client" >&2; exit 1
fi
if [ -z "${CONDA_PREFIX:-}" ]; then
    echo "error: no active conda environment (activate the build env first)." >&2; exit 1
fi

echo ">> [${PKG_NAME}] building${JOBS:+ (CPU_COUNT=${JOBS})} ..."
conda build "${RECIPE_DIR}" -c local -c conda-forge

# Locate the freshly built artifact (warm cache, so this is quick).
OUT="$(conda build "${RECIPE_DIR}" -c local -c conda-forge --output 2>/dev/null | grep -E '\.(conda|tar\.bz2)$' | tail -1)"
if [ -z "${OUT}" ] || [ ! -f "${OUT}" ]; then
    echo "error: could not locate the built artifact to upload." >&2; exit 1
fi

ANACONDA=(anaconda)
[ -n "${ANACONDA_API_TOKEN:-}" ] && ANACONDA+=(-t "${ANACONDA_API_TOKEN}")
echo ">> [${PKG_NAME}] uploading ${OUT} to channel '${CHANNEL}' ..."
"${ANACONDA[@]}" upload -u "${CHANNEL}" "${OUT}"

echo ">> [${PKG_NAME}] done. Install with: mamba install -c ${CHANNEL} -c conda-forge ${PKG_NAME}"
