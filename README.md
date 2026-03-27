# shiboken6-uibcdf

Experimental UIBCDF packaging repo for the first member of the provisional
Qt-for-Python standalone family.

Current scope:

- Linux
- Python 3.13
- version family: 6.10.2

Why this repo exists:

- molsysviewer packaging research showed that the standalone-critical Qt
  route is not a small add-on on top of the current conda-forge stack
- the clean provisional boundary now looks like an aligned family:
  - shiboken6-uibcdf
  - pyside6-essentials-uibcdf
  - pyside6-addons-uibcdf
- this repo owns only the shiboken6 layer of that family

Current source of truth:

- legacy bootstrap manifest copied into this repo during the original 6.9.2
  exploration:
  - manifests/shiboken6.files.txt
  - manifests/shiboken6.runtime.txt
- first self-contained packaging boundary staged in this repo during that
  bootstrap:
  - package_boundary/site-packages
- original validated environment used to derive that first boundary:
  /home/diego/Myopt/miniconda3/envs/molsyssuite-qt-spike
- upstream codebase reference:
  - ~/repos@others/pyside-setup

Current repo layout:

- upstream shiboken6 code is now staged directly in this repo:
  - ApiExtractor
  - generator
  - libshiboken
  - shibokenmodule
  - cmake
  - config.tests
  - data
  - tests
- packaging/devtools remain repo-local and experimental:
  - devtools/conda-build
  - devtools/conda-envs
  - manifests
  - package_boundary

Current packaging approach:

- current active path is source-build-driven for the `_uibcdf` namespace split
- the legacy manifest/boundary assets are kept as bootstrap evidence, not as
  the final source of truth for the 6.10.2 line

Current success criteria:

1. build `shiboken6-uibcdf` from source as a true `6.10.2` line
2. expose:
   - `shiboken6_uibcdf/Shiboken.abi3.so`
   - `shiboken6_uibcdf/libshiboken6.abi3.so.6.10`
3. keep the repo scoped to the first coexistence-capable member of the
   provisional UIBCDF Qt-for-Python family
