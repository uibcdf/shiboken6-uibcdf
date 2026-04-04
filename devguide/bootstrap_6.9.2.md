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

Current packaging has two phases.

### Phase 1: Manifest-Driven Boundary Discovery

- `devtools/conda-build/build.sh` copies the vendored `shiboken6` boundary
  from `package_boundary/site-packages` into `$SP_DIR` by default
- the source environment can be overridden with:
  - `SHIBOKEN6_UIBCDF_SOURCE_PREFIX`

This phase made the validated runtime boundary explicit and reproducible.

### Phase 2: Source-Build-Led Namespace Split

For coexistence with native `shiboken6`, Phase 1 is not sufficient.
The package now needs a true source rebuild so that embedded runtime helpers
also speak the suffixed namespace:

- `shiboken6_uibcdf`

The boundary and manifests are still useful evidence, but the final namespace
split can no longer be completed only by rewriting staged Python files.

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

But the test still failed during import because `Shiboken.abi3.so` embeds a
signature bootstrap that still imports canonical `shiboken6`.

The relevant source-side hook is:

- `libshiboken/embed/signature_bootstrap.py`

So the current conclusion is:

- simple repackaging of the validated boundary is not enough to finish the
  `_uibcdf` namespace split
- a true source rebuild is required for `shiboken6-uibcdf`

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
8. Run real `conda build`.
9. If the target is a suffixed coexistence namespace, continue until the
   source rebuild also removes embedded canonical imports such as those in
   `signature_bootstrap.py`.
10. Only after that, move on to the matching `Essentials` and `Addons` repos.

## Critical Runtime Bug Fixed (2026-04-01)

### `Module::get` slow path: "PySide6." vs "PySide6_uibcdf." prefix mismatch

**Symptom:** `import PySide6_uibcdf.QtCore` segfaults with:
```
PyTuple_Pack(n=1) ← crash
init_SomeType (in QtCore.abi3.so)   ← calls PyTuple_Pack(1, base_type)
libshiboken (incarnate lazy init)
PyObject_GetAttrString
init_SomeTypeStaticFields
PyInit_QtCore
```

**Root cause:** `Shiboken::Module::get(TypeInitStruct &typeStruct)` in
`libshiboken/sbkmodule.cpp` has a slow path that triggers when a type is first
needed (lazy initialization). It looks up the module from `sys.modules` using
the `fullName` field of the struct (e.g. `"PySide6.QtCore.QOperatingSystemVersionBase"`).

The slow path code was patched to check for `"PySide6_uibcdf."` prefix:
```c++
const bool usePySide = names.compare(0, 15, "PySide6_uibcdf.") == 0;
auto dotPos = usePySide ? names.find('.', 15) : names.find('.');
```

But the shiboken **generator** still emits `"PySide6.*"` fullNames in the
generated code (taken from the `package="PySide6.QtCore"` attribute in
typesystem XML files). So `usePySide = false` → `dotPos = 8` →
`modName = "PySide6"` → `PyDict_GetItem(sys.modules, "PySide6")` → **NULL**
→ returns NULL → `PyTuple_Pack(1, NULL)` → **SIGSEGV**.

**Fix applied** (`libshiboken/sbkmodule.cpp`, commit 14d0fd0):
```c++
// Remap "PySide6." → "PySide6_uibcdf." before the sys.modules lookup.
std::string remappedNames;
if (names.compare(0, 8, "PySide6.") == 0 && names.compare(0, 15, "PySide6_uibcdf.") != 0) {
    remappedNames = "PySide6_uibcdf" + std::string(names.substr(7));
    names = remappedNames;
}
const bool usePySide = names.compare(0, 15, "PySide6_uibcdf.") == 0;
```

This remapping is **unconditional and exclusive**: any `"PySide6.*"` name is
always rewritten to `"PySide6_uibcdf.*"`. It never falls back to the standard
`PySide6` package, so having both PySide6 and PySide6_uibcdf installed in the
same env is safe.

**Long-term ideal fix (not yet done):** Change `package="PySide6.QtCore"` to
`package="PySide6_uibcdf.QtCore"` in all typesystem XML files in
`pyside6-essentials-uibcdf`. That would make the generator emit correct
fullNames directly, eliminating the runtime remap entirely.

**How to debug similar crashes in future versions:**
1. Run `gdb --batch -ex run -ex bt --args python -c "import PySide6_uibcdf.QtCore"`.
2. Look for `PyTuple_Pack(n=...)` at frame 0 and `PyInit_*` near the bottom.
3. Get the crash address in the .so (`info sharedlibrary` for base, then compute offset).
4. Disassemble to find the `lea ... %rsi` instruction that loads the fullName string.
5. Inspect the string with `x/s <addr>`. That string tells you which type's lazy init failed.
6. Check if `sys.modules` would contain the module name extracted from that fullName.

## Second Runtime Bug Fixed (2026-04-02)

### `Module::import`: same "PySide6." prefix problem

**Symptom:** `import PySide6_uibcdf.QtGui` raised:
```
ImportError: could not import module 'PySide6.QtCore'
```
even though `import PySide6_uibcdf.QtCore` worked fine.

**Root cause:** `Shiboken::Module::import(const char *moduleName)` in
`libshiboken/sbkmodule.cpp` is called when a module loads its dependencies
(e.g. QtGui needs QtCore). The generated module init passes `"PySide6.QtCore"`
as the module name. `Module::import` calls `PyImport_ImportModule("PySide6.QtCore")`,
which fails because the installed package is `PySide6_uibcdf.QtCore`.

The previous fix patched only `Module::get` (type lookup slow path). This function
(`Module::import`) is a separate entry point that also needed the same remap.

**Fix applied** (`libshiboken/sbkmodule.cpp`, commit 4e60fb6):
```c++
PyObject *import(const char *moduleName)
{
    // UIBCDF patch: generated code requests "PySide6.X" but our package is "PySide6_uibcdf.X"
    std::string remapped;
    const char *resolvedName = moduleName;
    std::string_view nameView(moduleName);
    if (nameView.compare(0, 8, "PySide6.") == 0 && nameView.compare(0, 15, "PySide6_uibcdf.") != 0) {
        remapped = "PySide6_uibcdf" + std::string(nameView.substr(7));
        resolvedName = remapped.c_str();
    }
    // ... rest of function uses resolvedName
```

**When upgrading to 6.10.x**: check that BOTH `Module::get` AND `Module::import`
still have the remap. Upstream may have refactored either or both functions.

## Versioning and Build Numbers

The `version` field in `meta.yaml` always tracks the upstream Qt-for-Python
version (e.g. `6.9.2`). It changes only when the upstream version changes.

The `build.number` field is the mechanism for shipping corrections to the same
upstream version:

- **Bug in the recipe, in patches, or in the C++ source** (e.g. a new
  `sbkmodule.cpp` fix): increment `build.number` by 1, keep `version` as-is.
- **New upstream version** (e.g. 6.10.x): reset `build.number` to 0 and update
  `version`.

`conda update` / `mamba update` resolves packages by version first, then by
build number within the same version, so users will automatically receive the
corrected build when they run an update.

All three packages in the family (`shiboken6-uibcdf`, `pyside6-essentials-uibcdf`,
`pyside6-addons-uibcdf`) should be released together with the same build number
whenever a correction touches the shared runtime (e.g. a `libshiboken` patch
that affects all three).

Upload to the `uibcdf` channel with:

```bash
anaconda upload <path-to-package.conda> --user uibcdf --channel uibcdf
```

## Enum Disambiguation Fix (2026-04-04)

### Root cause: `findFlagsType` "last hope" matching unqualified names

**Symptom:** `QFileDialog` and `QMessageBox` built with `generate="no"` as workaround, or
produced incorrect C++ wrappers (`QFlags<QAbstractItemModel::CheckIndexOption>` instead of
`QFlags<QFileDialog::Option>`).

**Root cause (A) — `typedatabase.cpp` "last hope":**
`TypeDatabase::findFlagsType` has a fallback loop:
```cpp
for (auto it = d->m_flagsEntries.cbegin(); it != end; ++it) {
    if (it.key().endsWith(name)) { ... }
}
```
`m_flagsEntries` is a `QMap` (alphabetically sorted). When searching for unqualified
`"Options"`, `"QAbstractItemModel::CheckIndexOptions"` matches because `"CheckIndexOptions"`
ends with `"Options"`.

**Fix A** (`ApiExtractor/typedatabase.cpp`, commit `1c1d39f`):
```cpp
const QString scopedName = u"::"_s + name;
if (it.key().endsWith(scopedName)) { ... }
```
This rejects `"CheckIndexOptions"` (no `"::"` before `"Options"`) but accepts
`"QFileDialog::Options"` and `"QAbstractFileIconProvider::Options"`.

**Root cause (B) — `abstractmetabuilder.cpp` step 6 missing class scope:**
`findTypeEntriesHelper` step 6 calls `findFlagsType(qualifiedName)` with an unqualified
name (e.g. `"Options"`) when processing a class method. Without class context, the "last
hope" picks the first alphabetical match. `"QAbstractFileIconProvider::Options"` sorts
before `"QFileDialog::Options"`, so QFileIconProvider's inherited `options()` method also
gets wrongly typed as `QFileDialog::Option`.

**Fix B** (`ApiExtractor/abstractmetabuilder.cpp`, commit `f0da5b0`):
Before falling through to the general `findFlagsType(qualifiedName)` at step 6, try:
1. `findFlagsType(currentClass::qualifiedName)` — exact class match
2. `findFlagsType(baseClass::qualifiedName)` for each base class — inherited flags

Result:
- `QFileDialog` + `"Options"` → tries `"QFileDialog::Options"` → direct hit ✓
- `QFileIconProvider` + `"Options"` → tries `"QFileIconProvider::Options"` (fails) → tries
  `"QAbstractFileIconProvider::Options"` (base class, direct hit) ✓

**Effect on pyside6-essentials-uibcdf:**
`DROPPED_ENTRIES` for `QAbstractFileIconProvider.Option` is no longer needed.
`QFileDialog`, `QMessageBox`, and `QFileIconProvider` all build and import correctly.

**When upgrading to 6.10.x:** both patches are in
`ApiExtractor/typedatabase.cpp` and `ApiExtractor/abstractmetabuilder.cpp`.
Verify they are still present after vendoring the new upstream. The "last hope" logic is
unlikely to change upstream but check.

## Local Build and Upload

### Requirements

Install `anaconda-client` once (can be in the base env):
```bash
conda install -c conda-forge anaconda-client
```

### Build order

Always build in this order — each package depends on the previous:

```bash
# 1. shiboken6-uibcdf
cd /path/to/shiboken6-uibcdf
conda build devtools/conda-build \
    --channel conda-forge \
    --channel uibcdf

# 2. pyside6-essentials-uibcdf
cd /path/to/pyside6-essentials-uibcdf
conda build devtools/conda-build \
    --channel conda-forge \
    --channel uibcdf \
    --channel local

# 3. pyside6-addons-uibcdf
cd /path/to/pyside6-addons-uibcdf
conda build devtools/conda-build \
    --channel conda-forge \
    --channel uibcdf \
    --channel local
```

`--channel local` makes the freshly-built packages in the conda-bld cache visible
to the next build without uploading first.

### Install locally for testing

The conda solver can fail on complex envs when given version+build-string specs.
Use direct file paths instead:

```bash
conda install -n <env> \
    /path/to/conda-bld/linux-64/shiboken6-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/pyside6-essentials-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/pyside6-addons-uibcdf-6.9.2-*.conda
```

Or after running `conda index /path/to/conda-bld`:
```bash
conda install -n <env> \
    --channel /path/to/conda-bld \
    "shiboken6-uibcdf=6.9.2=*_3" \
    "pyside6-essentials-uibcdf=6.9.2=*_3" \
    "pyside6-addons-uibcdf=6.9.2=*_3"
```

### Upload to the uibcdf channel

```bash
anaconda upload \
    /path/to/conda-bld/linux-64/shiboken6-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/pyside6-essentials-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/pyside6-addons-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/qt6-positioning-uibcdf-6.9.2-*.conda \
    /path/to/conda-bld/linux-64/qt6-webengine-uibcdf-6.9.2-*.conda \
    --user uibcdf
```

Add `--force` to overwrite an existing build with the same version+build string.

## Multi-Python and Multi-Platform

### Multiple Python versions (3.11, 3.12, 3.13)

The `meta.yaml` currently pins `python =3.13` in host/run. To support 3.11 and 3.12:

**Option A — separate builds per version (simplest):**
Maintain separate branches or build configs. For each Python version:
1. Change `python =3.13` → `python =3.11` (or `=3.12`) in meta.yaml.
2. Run `conda build` in a conda env that has that Python version installed.
3. Upload all resulting `.conda` files.

**Option B — conda build matrix (cleaner long-term):**
Add a `conda_build_config.yaml` alongside `meta.yaml`:
```yaml
python:
  - "3.11"
  - "3.12"
  - "3.13"
```
Change `meta.yaml` to use `{{ python }}` instead of hardcoded `=3.13`.
`conda build` will then build one package per Python version automatically.
The build strings will differ: `py311_*`, `py312_*`, `py313_*`.

**Caveat:** The shiboken fixes (`Module::get`, `Module::import`, enum disambiguation)
are Python-version-independent. The same patches apply for 3.11/3.12. The main
difference is that Python 3.13 has some API changes (e.g. PEP 703 free-threaded);
`pep384impl.cpp` may need adjustments for older Python versions if `Py_LIMITED_API`
behavior differs.

### macOS (arm64 and x86_64)

The shiboken patches are platform-independent C++ — they will compile on macOS
without modification.

Key differences vs Linux:

- **Shared library suffix**: `.dylib` instead of `.so`. Build scripts and test
  commands need updating (e.g. `test -f "$SP_DIR/PySide6_uibcdf/Shiboken.abi3.so"`
  → `.dylib`).
- **RPATH**: macOS uses `@rpath` instead of `$ORIGIN`. The `install_name_tool`
  or CMake's `INSTALL_RPATH` may need adjustment so `libshiboken6.abi3.dylib`
  is found at runtime.
- **Compiler**: use conda-forge's `clang` (via `{{ compiler('cxx') }}`) — already
  handled by the Jinja2 macro.
- **Qt6**: `qt6-main` and `qt6-webengine` are available for macOS on conda-forge.
  Verify the versions align with 6.9.2 on both arm64 and x86_64.
- **arm64**: shiboken itself builds on arm64 without issues. Qt's QtWebEngine
  (Chromium-based) historically lagged on arm64 — check conda-forge availability.
- **CI**: the self-hosted runner plan should include a macOS arm64 runner. Without
  hardware-accelerated builds, compile times will be very long on emulated arm64.

Recommended first step: get a clean macOS arm64 build of shiboken6-uibcdf alone
(no PySide6) to validate the recipe machinery, then layer essentials on top.

### Windows

Significantly more work than macOS. Key differences:

- **Compiler**: MSVC (via `{{ compiler('cxx') }}`). Shiboken requires MSVC on Windows
  (not MinGW). Conda-forge has MSVC compilers available.
- **DLL naming**: `Shiboken.pyd` or `Shiboken.abi3.pyd` instead of `.so`/`.dylib`.
  `libshiboken6.abi3.dll` instead of `.so`.
- **Path separators and RPATH**: Windows uses `PATH`-based DLL discovery (no RPATH).
  Conda handles this with `conda.pth` and `Library/bin` convention — Qt DLLs should
  land in `$PREFIX/Library/bin`, not `$PREFIX/lib`.
- **build.sh → bld.bat**: conda-build uses `bld.bat` on Windows, not `build.sh`.
  Add `devtools/conda-build/bld.bat` for each package.
- **Qt6 on Windows**: conda-forge has `qt6-main` for Windows. QtWebEngine availability
  on Windows in conda-forge is limited — check before planning addons for Windows.
- **The sbkmodule.cpp patches**: use `std::string_view` and `std::string`, which
  are standard C++17 — no Windows-specific changes needed.

Recommended approach: Windows support is a non-trivial investment. Suggest tackling
it only after macOS arm64 is working, and only if there is a concrete user need.

## Things To Keep Stable

- keep the repo version line aligned with the family version
- do not silently mix payloads from different Qt-for-Python versions
- treat this repo as one member of a family, not as a standalone decision
- keep this document updated when the recipe or source boundary changes
- **when upgrading to 6.10.x**: re-check `libshiboken/sbkmodule.cpp` to confirm
  the "PySide6." remap is present in **both** `Module::get` AND `Module::import`
- **when upgrading to 6.10.x**: verify enum disambiguation patches in
  `ApiExtractor/typedatabase.cpp` and `ApiExtractor/abstractmetabuilder.cpp`
  are still present and correct
