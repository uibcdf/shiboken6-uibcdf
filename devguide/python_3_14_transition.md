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

The first recipe built source version 6.10.1 against `qt6-main=6.10.1` and
Python 3.14. It intentionally created a `py314` package with a
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

## Python 3.11–3.13 regression experiments

On 23 September 2026, a disposable copy of this candidate changed only the
recipe's Python host/run pins from 3.14 to 3.11. A Linux-64 Conda build and
its package tests passed, producing
`shiboken6-uibcdf-6.10.1-py311h3fd9d12_0.conda` (SHA-256
`d2754cabe053fc279df1f12ce18dcaca009fa9b041091429f97dca384db95a45`).
The test environment imported `shiboken6_uibcdf` and ran
`shiboken6 --version`. This is evidence for one local 3.11 cell, not a
multi-interpreter ABI3 claim.
The artifact was used to build and test the matching Essentials 3.11
experiment. General build-order and storage lessons are recorded in the
[Addons family build practices](https://github.com/uibcdf/pyside6-addons-uibcdf/blob/python-3.14-qt-6.10.1/devguide/qt_family_build_practices.md).

The same disposable pin substitution was repeated for Python 3.12 and
3.13 on Linux-64. Both Conda builds and package tests passed. Their
artifacts were `py312h3fd9d12_0` (SHA-256
`ef149953fe0a1f76ac4dbe146ab0a0e88e59f46268937af31efdfaa386ce2ffa`)
and `py313h3fd9d12_0` (SHA-256
`a135ac3c679036e03aadf8fb75c9f804c6890065284abdb6779086acc7c37ffe`).
Each was then installed with the matching Essentials/Addons variant in an
independent clean environment, without canonical PySide6. The full family
imported and loaded local HTML under Xvfb. The Python 3.13 build emitted
a non-fatal deprecated-Python-API warning; it did not fail the package test.

The branch recipe has since been changed to select Python from Conda's
explicit `--python` variant instead of hard-pinning 3.14. A no-download,
non-finalized render produced distinct `py311`, `py312`, `py313`, and `py314`
build strings with matching Python host variants. On Linux-64, a full
`conda build --python 3.12` of the revised recipe then passed its package
tests using `CPU_COUNT=12`. The resulting local artifact has SHA-256
`1faa8deecc53c65b0275c4716e27e50286f6ab5e6ca69f740e979085af8a5887`.
Its finalized `info/index.json` declares `python >=3.12,<3.13.0a0`,
`python_abi 3.12.* *_cp312`, `qt6-main 6.10.1.*`, and `libclang13`.
This verifies the revised recipe in one cell; it does not validate the
other three cells or any staged/public package.

## Remaining gates

1. Test Shiboken behavior beyond import and version checks: signatures,
   generated bindings, and ownership/lifetime. Local downstream Essentials
   builds have passed for Python 3.11–3.14 on Linux, with 3.11–3.13
   using disposable recipe variants.
2. Build and test the revised, variant-selected recipe for Python 3.11,
   3.13, and 3.14 and inspect each finalized runtime constraint. The 3.12
   cell passed locally; current disposable
   experiments support per-interpreter packages, not a single ABI3 package.
3. Coordinate with Essentials, Addons, Positioning and WebEngine 6.10.1,
   then stage and validate the full MolSysViewer Qt host. Linux-only local
   evidence cannot authorize release or a public Python 3.14 claim.
