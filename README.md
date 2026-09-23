# shiboken6-uibcdf

Experimental UIBCDF packaging of the Shiboken layer for the standalone
Qt-for-Python stack used by MolSysViewer. This repository carries a suffixed
`shiboken6_uibcdf` import namespace so it can be developed separately from
the canonical PySide installation.

The published 6.9.2 line targets Linux and Python 3.13. The
`python-3.14-qt-6.10.1` branch is an **unreleased candidate** built from
official Qt for Python 6.10.1 source plus the retained UIBCDF namespace
patches. Its first target is Linux/Python 3.14 with conda-forge
`qt6-main=6.10.1`. Neither the source branch nor an isolated package import
establishes support for the full five-package Qt host.

The Conda recipe builds Shiboken from the source in this repository. Files in
`manifests/` and `package_boundary/` document the original 6.9.2 bootstrap;
they are not the recipe input. The 3.14 migration, verification and remaining
gates are tracked in [the transition guide](devguide/python_3_14_transition.md)
and [issue #1](https://github.com/uibcdf/shiboken6-uibcdf/issues/1).
