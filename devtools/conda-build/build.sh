#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="${SRC_DIR}/build-conda"
rm -rf "${BUILD_DIR}"

export LLVM_INSTALL_DIR="${PREFIX}"

cmake -S "${SRC_DIR}" -B "${BUILD_DIR}" -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DPython_EXECUTABLE="${PYTHON}" \
  -DPYTHON_SITE_PACKAGES="${SP_DIR}" \
  -DSHIBOKEN_BUILD_LIBS=ON \
  -DSHIBOKEN_BUILD_TOOLS=ON \
  -DBUILD_TESTS=OFF \
  -DDISABLE_DOCSTRINGS=ON

cmake --build "${BUILD_DIR}" --parallel "${CPU_COUNT:-2}"
cmake --install "${BUILD_DIR}"
