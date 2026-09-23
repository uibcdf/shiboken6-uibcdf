# Shiboken 6.10.1 / Python 3.14 transition

Issue: [`uibcdf/shiboken6-uibcdf#1`](https://github.com/uibcdf/shiboken6-uibcdf/issues/1).
Status: isolated Linux/Python 3.14 candidate; no release or channel upload.

## Source port

This branch starts from the repository's 6.9.2 line. The upstream input is
the official `pyside-setup` tag `v6.10.1`, peeled commit
`42be1cc7d9973b7da44c048981001b823b329704`, specifically its
`sources/shiboken6` subtree. The full upstream 6.9.2-to-6.10.1 change was
applied to that source subtree. The repository's packaging, bootstrap assets,
and UIBCDF namespace patches were retained.

Upstream changed 127 Shiboken source files. The fork's 6.9.2 source had 20
files differing from the official 6.9.2 baseline, and 12 of those also
changed upstream. The overlapping patches were reviewed individually:

- CMake config no longer uses the old build/install `PATH_VARS`; the removed
  fork-specific module path was not carried into an unused variable.
- The already-backported `sbkpep.h` and `sbkpepbuffer.h` files match upstream
  6.10.1 byte-for-byte. The fork already had the fully qualified type-name
  helper; its simple implementation is the active branch of the upstream
  implementation.
- The upstream changes to module lazy loading, signatures, and Qt type
  mappings were incorporated while preserving `shiboken6_uibcdf` and
  `PySide6_uibcdf` names.

The original 6.9.2 checkout has a pre-existing local edit to its bootstrap
guide. This branch uses a separate worktree and does not alter that checkout.

## First package experiment

The recipe now builds source version 6.10.1 against `qt6-main=6.10.1` and
Python 3.14. It intentionally creates a `py314` package with a
`python_abi 3.14.* *_cp314` runtime dependency. Although the extension is
named `.abi3.so`, a genuinely multi-interpreter package needs its own
stable-ABI build contract and tests on every claimed interpreter; changing
the runtime string alone is not enough.

The first local Conda build and package test passed on Linux x86-64 with
Python 3.14.7. A separate clean Conda environment installed its artifact
from the local channel with exact `qt6-main=6.10.1`; importing
`shiboken6_uibcdf` reported version 6.10.1, its `isValid` function was
present, and the `shiboken6 --version` generator command reported 6.10.1.
This first artifact's metadata allowed Qt 6.10.2, because the upstream Qt
run export bounded only the 6.10 minor line.

A second local build and package test passed after the recipe pinned
`qt6-main=6.10.1` and added the generator version command to the package
test. Its packaged metadata correctly contains `qt6-main 6.10.1.*` and
`python_abi 3.14.* *_cp314`. However, Conda's binary inspection revealed
that the installed generator also needs `libclang.so.13` and the recipe did
not directly declare the providing `libclang13` package. The earlier clean
installation supplied it incidentally. The candidate recipe now names
`libclang13` as an explicit runtime dependency. The final third build and
package test passed. Its `info/index.json` declares `libclang13`,
`qt6-main 6.10.1.*`, `python >=3.14,<3.15.0a0`, and
`python_abi 3.14.* *_cp314`.

The final Linux x86-64 artifact is
`shiboken6-uibcdf-6.10.1-py314h3fd9d12_0.conda`, SHA-256
`f6c74bface06df1506919a29d48102cd83c5f7bf2b1b7731ac5b853e19eb7fce`.
An independent clean Conda environment installed exactly this local artifact
alongside conda-forge Python 3.14.7, Qt 6.10.1, and `libclang13`.
`shiboken6_uibcdf` imported, reported version 6.10.1, exposed `isValid`,
and `shiboken6 --version` succeeded. Neither earlier artifact should be
promoted. The final artifact also remains local and unreleased pending the
downstream and platform gates.

## Remaining gates

1. Test Shiboken behavior beyond import and version checks: signatures,
   generated bindings, ownership/lifetime and the downstream Essentials build.
2. Decide whether a single ABI3 package can honestly serve Python 3.11–3.14;
   otherwise build and test a per-interpreter matrix.
3. Coordinate with Essentials, Addons, Positioning and WebEngine 6.10.1,
   then stage and validate the full MolSysViewer Qt host. Linux-only local
   evidence cannot authorize release or a public Python 3.14 claim.
