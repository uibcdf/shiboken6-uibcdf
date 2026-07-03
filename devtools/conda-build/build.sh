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

CANONICAL_SP_DIR="${SP_DIR}/shiboken6"
SPLIT_SP_DIR="${SP_DIR}/shiboken6_uibcdf"

rm -rf "${SPLIT_SP_DIR}"
mv "${CANONICAL_SP_DIR}" "${SPLIT_SP_DIR}"

cp -a "${PREFIX}/lib/libshiboken6.abi3.so"* "${SPLIT_SP_DIR}/"

if [ -d "${SP_DIR}/shiboken6-6.9.2.dist-info" ]; then
  mv "${SP_DIR}/shiboken6-6.9.2.dist-info" "${SP_DIR}/shiboken6_uibcdf-6.9.2.dist-info"
  perl -0pi -e 's/^shiboken6$/shiboken6_uibcdf/m' "${SP_DIR}/shiboken6_uibcdf-6.9.2.dist-info/top_level.txt" || true
fi
