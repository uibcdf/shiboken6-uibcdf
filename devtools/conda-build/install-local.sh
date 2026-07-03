#!/usr/bin/env bash
#
# install-local.sh — build this package from its local conda recipe and install
# it into the active conda environment. For local testing WITHOUT waiting for the
# uibcdf conda channel.
#
# This is a COMPILED package (cmake/ninja/clang, pulled by the recipe build deps).
#
# Build order for the whole Qt-for-Python family — run each repo's
# devtools/conda-build/install-local.sh in this order (each depends on the
# previous ones being built + installed):
#     1. shiboken6-uibcdf           <-- this repo
#     2. pyside6-essentials-uibcdf
#     3. qt6-positioning-uibcdf     (repackage: needs QT6_*_SOURCE_* — see its script)
#     4. qt6-webengine-uibcdf       (repackage: needs QT6_*_SOURCE_*)
#     5. pyside6-addons-uibcdf      (needs all of the above)
#
# Usage:
#     conda activate <target-env>
#     ./devtools/conda-build/install-local.sh
#
set -euo pipefail

PKG_NAME="shiboken6-uibcdf"
RECIPE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! conda build --version >/dev/null 2>&1; then
    echo "error: 'conda build' is not available." >&2
    echo "       install it with:  mamba install -n base conda-build" >&2
    exit 1
fi

if [ -z "${CONDA_PREFIX:-}" ]; then
    echo "error: no active conda environment (CONDA_PREFIX is empty)." >&2
    echo "       activate the target env first:  conda activate <env>" >&2
    exit 1
fi

echo ">> [${PKG_NAME}] building from recipe: ${RECIPE_DIR}"
# -c local  : resolve sibling uibcdf packages built earlier from conda-bld
# -c conda-forge : qt6-main, clangdev/llvmdev, compilers, cmake, ninja, ...
conda build "${RECIPE_DIR}" -c local -c conda-forge

echo ">> [${PKG_NAME}] installing into active env: ${CONDA_PREFIX}"
mamba install -y -c local -c conda-forge "${PKG_NAME}"

echo ">> [${PKG_NAME}] done."
