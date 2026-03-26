# Bootstrap 6.9.2

## Scope

This repo currently tracks the first Linux/Python 3.13 experimental UIBCDF line
for `shiboken6` version `6.9.2`.

This is not yet a polished upstream-quality packaging recipe. It is the first
reproducible UIBCDF line derived from the validated standalone investigation.

## Why This Repo Exists

The MolSysViewer standalone packaging investigation showed that the working Qt
for Python path is better modeled as an aligned family than as a thin extension
on top of the current conda-forge base.

That family is:

- `shiboken6-uibcdf`
- `pyside6-essentials-uibcdf`
- `pyside6-addons-uibcdf`

This repo owns only the `shiboken6` slice.

## Where The Code Came From

The upstream source for this repo was taken from the local checkout:

- `/home/diego/repos@others/pyside-setup`

Relevant upstream subtree for this repo:

- `/home/diego/repos@others/pyside-setup/sources/shiboken6`

The current repo contains vendored upstream code copied from that subtree,
including:

- `ApiExtractor`
- `generator`
- `libshiboken`
- `shibokenmodule`
- `cmake`
- `config.tests`
- `data`
- `tests`
- top-level build files such as `CMakeLists.txt`, `.cmake.conf`, `AUTHORS`

## Where The Packaging Boundary Came From

The initial package boundary was not guessed from source layout alone.
It was derived from a validated runtime environment:

- `/home/diego/Myopt/miniconda3/envs/molsyssuite-qt-spike`

The manifest was generated from the installed wheel-family files and then
copied into this repo:

- `manifests/shiboken6.files.txt`
- `manifests/shiboken6.runtime.txt`

The first self-contained packaging boundary was then copied into this repo
under:

- `package_boundary/site-packages`

The runtime-critical files are:

- `shiboken6/Shiboken.abi3.so`
- `shiboken6/libshiboken6.abi3.so.6.9`

## Current Packaging Decision

Current first-pass packaging is manifest-driven.

That means:

- `devtools/conda-build/build.sh` copies the vendored `shiboken6` boundary
  from `package_boundary/site-packages` into `$SP_DIR` by default
- the source environment can be overridden with:
  - `SHIBOKEN6_UIBCDF_SOURCE_PREFIX`
- this is intentionally a boundary-finding step before a more source-build-led
  recipe is attempted

## Why We Chose This First Step

This first step answers a narrow but important question:

- can we package the validated `shiboken6` boundary cleanly and reproducibly
  before tackling the much larger `PySide6_Essentials` and `PySide6_Addons`
  layers?

It also gives a small package where the runtime payload is easy to inspect.

## Current Validation

A local non-conda smoke validation has already passed for this repo:

- `build.sh` staged the manifest-listed files into a temporary `site-packages`
- `import shiboken6` worked from that staged boundary

At the time this note was written, `conda-build` itself was not available in
the active shell, so a true `conda build` run still needs to be performed.

## Relationship To The Other Two Repos

Dependency order for the family is:

1. `shiboken6-uibcdf`
2. `pyside6-essentials-uibcdf`
3. `pyside6-addons-uibcdf`

`PySide6_Essentials` depends on `shiboken6`.
`PySide6_Addons` depends on both `shiboken6` and `PySide6_Essentials`.

## How To Recreate This Repo For A Future 6.10.x Line

Use this same sequence, but on a new version branch such as `6.10.x` or the
exact version branch you decide to support.

1. Validate a working environment for the target family version.
2. Regenerate the file manifest for `shiboken6` from that environment.
3. Vendor the upstream source from the matching `pyside-setup` version.
4. Copy the new manifests into `manifests/`.
5. Update `devtools/conda-build/meta.yaml` version pins and runtime tests.
6. Update `devtools/conda-build/build.sh` if the installed layout changed.
7. Run a temporary `site-packages` smoke check.
8. Run real `conda build` once `conda-build` is available.
9. Only after that, move on to the matching `Essentials` and `Addons` repos.

## Things To Keep Stable

- keep the repo version line aligned with the family version
- do not silently mix payloads from different Qt-for-Python versions
- treat this repo as one member of a family, not as a standalone decision
- keep this document updated when the recipe or source boundary changes
