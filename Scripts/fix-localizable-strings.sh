#!/usr/bin/env bash

# A script that invokes all the various linting-like tools in the Python `fix-localizable-strings`
# script against all the English .strings files in the repo.
#
# Usage: fix-localizable-strings.sh [--dry-run]
# Any extra arguments are forwarded to the underlying Python script.

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

# The main Localizable.strings file, used with delete-unused.
MAIN_STRINGS="BitwardenResources/Localizations/en.lproj/Localizable.strings"

# Swift source directories that reference the SwiftGen-generated Localizations enum.
SWIFT_SOURCE_DIRS=(
    "AuthenticatorShared"
    "Bitwarden"
    "BitwardenKit"
    "BitwardenResources"
    "BitwardenShared"
    "TestHarnessShared"
)

# Build the --swift-source arguments once for use inside the loop.
swift_source_args=()
for dir in "${SWIFT_SOURCE_DIRS[@]}"; do
    swift_source_args+=(--swift-source "${REPO_ROOT}/${dir}")
done

# Run each fix-localizable-strings command against every strings file.
# Any extra arguments passed to this script (e.g. --dry-run) are forwarded as-is.
for strings_file in "${STRINGS_FILES[@]}"; do
    echo "${strings_file}"
    python3 "${PYTHON}" delete-duplicates --strings "${REPO_ROOT}/${strings_file}" "$@"
    # delete-unused only applies to the main Localizable.strings because it works
    # by scanning for Localizations.X references, which maps exclusively to the
    # SwiftGen-generated Localizations enum produced from that file. The other
    # strings files (AppShortcuts, Watch, TestHarness) use different access
    # mechanisms and are not covered by this detection strategy.
    if [[ "${strings_file}" == "${MAIN_STRINGS}" ]]; then
        python3 "${PYTHON}" delete-unused --strings "${REPO_ROOT}/${strings_file}" "${swift_source_args[@]}" "$@"
    fi
done
