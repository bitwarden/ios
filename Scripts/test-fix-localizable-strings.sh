#!/usr/bin/env bash
# Runs the Python unit tests for the fix-localizable-strings script.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/fix-localizable-strings"
python3 -m unittest discover -s tests -v
