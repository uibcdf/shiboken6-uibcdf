# Bootstrap 6.10.2

## Scope

This repo currently tracks the first Linux/Python 3.13 experimental UIBCDF line
for `shiboken6` version `6.10.2`.

This is not yet a polished upstream-quality packaging recipe. It is the current
reproducible UIBCDF line after pivoting away from an earlier `6.9.2` bootstrap
that turned out to vendor `6.10.2` source.

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

That bootstrap manifest was generated from the installed wheel-family files and then
copied into this repo:

- `manifests/shiboken6.files.txt`
- `manifests/shiboken6.runtime.txt`

The first self-contained packaging boundary was then copied into this repo
under:

- `package_boundary/site-packages`

Those bootstrap runtime-critical files are:

- `shiboken6/Shiboken.abi3.so`
- `shiboken6/libshiboken6.abi3.so.6.9`

They remain useful historical evidence, but they are no longer the version line
that this repo is treating as authoritative.

## Current Packaging Decision

Current packaging has two phases.

### Phase 1: Manifest-Driven Boundary Discovery

- `devtools/conda-build/build.sh` copies the vendored `shiboken6` boundary
  from `package_boundary/site-packages` into `$SP_DIR` by default
- the source environment can be overridden with:
  - `SHIBOKEN6_UIBCDF_SOURCE_PREFIX`

This phase made the validated runtime boundary explicit and reproducible.
It began on top of the `6.9.2` wheel family.

### Phase 2: Source-Build-Led Namespace Split

For coexistence with native `shiboken6`, Phase 1 is not sufficient.
The package now needs a true source rebuild so that embedded runtime helpers
also speak the suffixed namespace:

- `shiboken6_uibcdf`

The boundary and manifests are still useful evidence, but the final namespace
split can no longer be completed only by rewriting staged Python files.

This source-build phase also exposed that the vendored upstream source currently
in the repo is on the `6.10.2` line, which is why this repo has now been
realigned to `6.10.2` instead of continuing to pretend it is a `6.9.2` branch.

## Why We Chose This First Step

This first step answers a narrow but important question:

- can we package the validated `shiboken6` boundary cleanly and reproducibly
  before tackling the much larger `PySide6_Essentials` and `PySide6_Addons`
  layers?

It also gives a small package where the runtime payload is easy to inspect.
That decision was still correct even though it did not finish the final
namespace split by itself.

## Current Validation

Validation has happened at two levels.

### Boundary Repackaging Validation

A local non-conda smoke validation passed for the original boundary:

- `build.sh` staged the manifest-listed files into a temporary `site-packages`
- `import shiboken6` worked from that staged boundary

That proved the runtime boundary itself was packageable under the canonical
namespace.

### Suffixed Namespace Validation

The current target is:

- `shiboken6_uibcdf`

The first true `conda build` attempt for that suffixed namespace reached the
test phase and proved that:

- the staged layout can be rewritten to `shiboken6_uibcdf/`
- `__init__.py` can be rewritten away from `shiboken6.Shiboken`

That specific blocker is now closed. The current source-build now:

- configures successfully
- compiles `libshiboken`, `ApiExtractor`, and the `shiboken6` generator
- installs into the `_uibcdf` namespace

The current remaining blocker is much narrower:

- the recipe and tests must stay aligned with the actual `6.10.2` source line
- not with the old bootstrap expectation of `libshiboken6.abi3.so.6.9`

That blocker is now closed too:

- `devtools/conda-build/meta.yaml` now tests for
  `shiboken6_uibcdf/libshiboken6.abi3.so.6.10`
- the test had to be corrected to look for that shared library under
  `$PREFIX/shiboken6_uibcdf/`, not inside `site-packages/`
- with that adjustment, `conda build ../../devtools/conda-build` now completes
  successfully for:
  - `shiboken6-uibcdf-6.10.2-py313h3fd9d12_0.conda`

So the repo has now crossed the first packaging threshold:

- a true source-built `_uibcdf` package exists
- it installs and imports successfully under test
- and the work can move on to `pyside6-essentials-uibcdf` from a much stronger
  base

The relevant source-side hook is:

- `libshiboken/embed/signature_bootstrap.py`

So the current conclusion is:

- simple repackaging of the validated boundary is not enough to finish the
  `_uibcdf` namespace split
- a true source rebuild is required for `shiboken6-uibcdf`
- that source rebuild is now the authoritative path for this repo
- and this repo should stay aligned with the actual vendored source version

## Relationship To The Other Two Repos

Dependency order for the family is:

1. `shiboken6-uibcdf`
2. `pyside6-essentials-uibcdf`
3. `pyside6-addons-uibcdf`

`PySide6_Essentials` depends on `shiboken6`.
`PySide6_Addons` depends on both `shiboken6` and `PySide6_Essentials`.

## How To Recreate This Repo For A Future Line

Use this same sequence, but on a new exact version branch such as `6.11.x` or
whatever source line you decide to support next.

1. Validate a working environment for the target family version.
2. Regenerate the file manifest for `shiboken6` from that environment.
3. Vendor the upstream source from the matching `pyside-setup` version.
4. Copy the new manifests into `manifests/`.
5. Update `devtools/conda-build/meta.yaml` version pins and runtime tests.
6. Update `devtools/conda-build/build.sh` if the installed layout changed.
7. Run a temporary `site-packages` smoke check.
8. Run real `conda build`.
9. If the target is a suffixed coexistence namespace, continue until the
   source rebuild also removes embedded canonical imports such as those in
   `signature_bootstrap.py`.
10. Only after that, move on to the matching `Essentials` and `Addons` repos.

## Things To Keep Stable

- keep the repo version line aligned with the actual vendored source version
- do not silently mix payloads from different Qt-for-Python versions
- treat this repo as one member of a family, not as a standalone decision
- keep this document updated when the recipe or source boundary changes
