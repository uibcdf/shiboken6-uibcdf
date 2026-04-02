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

## Things To Keep Stable

- keep the repo version line aligned with the family version
- do not silently mix payloads from different Qt-for-Python versions
- treat this repo as one member of a family, not as a standalone decision
- keep this document updated when the recipe or source boundary changes
- **when upgrading to 6.10.x**: re-check `libshiboken/sbkmodule.cpp` to confirm
  the "PySide6." remap is present in **both** `Module::get` AND `Module::import`
