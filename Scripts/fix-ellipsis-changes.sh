#!/usr/bin/env bash
#
# Script to fix three-dot sequences (...) with proper ellipsis characters (…) in .strings files.
# Can be used standalone or as a git pre-commit hook.
# Usage: ./Scripts/fix-ellipsis-changes.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SCRIPT_DIR}/fix-localizable-strings/main.py"

STRINGS_FILES=(
    "Bitwarden/Application/Support/AppShortcutsLocalizations/en.lproj/AppShortcuts.strings"
    "BitwardenResources/Localizations/en.lproj/Localizable.strings"
    "BitwardenWatchApp/Localization/en.lproj/Localizable.strings"
    "TestHarnessShared/UI/Platform/Application/Support/Localizations/en.lproj/Localizable.strings"
)

FIXED_FILES=()
for file in "${STRINGS_FILES[@]}"; do
    [ -f "${REPO_ROOT}/${file}" ] || continue
    output=$(python3 "${PYTHON}" fix-ellipsis --strings "${REPO_ROOT}/${file}")
    if echo "$output" | grep -q "^  Fixed"; then
        FIXED_FILES+=("${file}")
        git add "${REPO_ROOT}/${file}"
    fi
done

if [ ${#FIXED_FILES[@]} -gt 0 ]; then
    echo "✅ Fixed ellipsis sequences in ${#FIXED_FILES[@]} file(s):"
    for file in "${FIXED_FILES[@]}"; do
        echo "  ${file}"
    done
fi
