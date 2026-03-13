#!/usr/bin/env bash
set -euo pipefail

# Resolve paths relative to this script so it can be run from anywhere.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SCRIPT_DIR}/fix-localizable-strings/main.py"

STRINGS_FILES=(
    "Bitwarden/Application/Support/AppShortcutsLocalizations/en.lproj/AppShortcuts.strings"
    "BitwardenResources/Localizations/en.lproj/Localizable.strings"
    "BitwardenWatchApp/Localization/en.lproj/Localizable.strings"
    "TestHarnessShared/UI/Platform/Application/Support/Localizations/en.lproj/Localizable.strings"
)

# Run each fix-localizable-strings command against every strings file.
# Any extra arguments passed to this script (e.g. --dry-run) are forwarded as-is.
for strings_file in "${STRINGS_FILES[@]}"; do
    echo "${strings_file}"
    python3 "${PYTHON}" delete-duplicates --strings "${REPO_ROOT}/${strings_file}" "$@"
done
