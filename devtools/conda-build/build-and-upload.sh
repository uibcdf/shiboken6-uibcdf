#!/usr/bin/env bash
set -euo pipefail

# The 6.10.1 Qt/PySide family is a coordinated, staging-first release.
# This historical direct-to-main entry point is deliberately disabled.
echo "Direct Conda upload is disabled for the Qt/PySide family. Use the staging workflow and promote only exact, tested artifacts." >&2
exit 2
