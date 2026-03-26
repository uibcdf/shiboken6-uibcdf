# shiboken6-uibcdf

Experimental UIBCDF packaging repo for the first member of the provisional
Qt-for-Python standalone family.

Current scope:

- Linux
- Python 3.13
- version family: 6.9.2

Why this repo exists:

- molsysviewer packaging research showed that the standalone-critical Qt
  route is not a small add-on on top of the current conda-forge stack
- the clean provisional boundary now looks like an aligned family:
  - shiboken6-uibcdf
  - pyside6-essentials-uibcdf
  - pyside6-addons-uibcdf
- this repo owns only the shiboken6 layer of that family

Current source of truth:

- validated environment:
  /home/diego/Myopt/miniconda3/envs/molsyssuite-qt-spike
- local manifest copied into this repo:
  - manifests/shiboken6.files.txt
  - manifests/shiboken6.runtime.txt
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

Current packaging approach:

- first pass is manifest-driven rather than source-build-driven
- `devtools/conda-build/build.sh` copies the validated `shiboken6` boundary
  from the known-good environment into `$SP_DIR`
- the source environment can be overridden with:
  - `SHIBOKEN6_UIBCDF_SOURCE_PREFIX`

First-pass success criteria:

1. package the shiboken6 wheel boundary in a conda-shaped recipe
2. expose:
   - shiboken6/Shiboken.abi3.so
   - shiboken6/libshiboken6.abi3.so.6.9
3. keep the repo scoped to boundary-finding, not final polished release flow
