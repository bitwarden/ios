#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SCRIPT_DIR}/fix-localizable-strings/main.py"

STRINGS_FILES=(
    "BitwardenResources/Localizations/en.lproj/Localizable.strings"
    "TestHarnessShared/UI/Platform/Application/Support/Localizations/en.lproj/Localizable.strings"
)

for strings_file in "${STRINGS_FILES[@]}"; do
    python3 "${PYTHON}" delete-duplicates --strings "${REPO_ROOT}/${strings_file}" "$@"
done
