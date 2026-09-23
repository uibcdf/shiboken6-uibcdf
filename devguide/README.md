# Devguide

This directory records the local packaging and maintenance recipe for shiboken6-uibcdf.

Current entrypoint:

- [python_3_14_transition.md](python_3_14_transition.md) — the unreleased
  6.10.1/Python 3.14 candidate and its gates.

The aligned family's local build order, channel provenance, interpreter
matrix, and disk-space precautions are collected in the
[Addons family build practices](https://github.com/uibcdf/pyside6-addons-uibcdf/blob/python-3.14-qt-6.10.1/devguide/qt_family_build_practices.md).

Historical bootstrap:

- [bootstrap_6.9.2.md](bootstrap_6.9.2.md) — the experimental 6.9.2 packaging
  line. Read it when investigating that line, not as current 6.10.1 instructions.

Purpose:

- record where the code came from
- record why this repo exists inside the provisional UIBCDF Qt-for-Python family
- distinguish tested local candidates from staged and published packages
