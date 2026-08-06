#!/usr/bin/env bash
#
# Script to fix three-dot sequences (...) with proper ellipsis characters (…) in .strings files.
# Can be used standalone or as a git pre-commit hook.
# Usage: ./Scripts/fix-ellipsis-changes.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SCRIPT_DIR}/fix-localizable-strings/main.py"

# Only operate on staged .strings files to avoid silently staging unrelated unstaged changes
if [ -n "${GIT_INDEX_FILE:-}" ]; then
    STAGED_STRINGS=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.strings$' || true)
else
    STAGED_STRINGS=$(git diff --name-only --diff-filter=ACM HEAD 2>/dev/null | grep '\.strings$' || \
                     git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep '\.strings$' || true)
fi

if [ -z "$STAGED_STRINGS" ]; then
    exit 0
fi

FIXED_FILES=()
while IFS= read -r file; do
    [ -f "${REPO_ROOT}/${file}" ] || continue
    output=$(python3 "${PYTHON}" fix-ellipsis --strings "${REPO_ROOT}/${file}")
    if echo "$output" | grep -q "^  Fixed"; then
        FIXED_FILES+=("${file}")
        git add "${REPO_ROOT}/${file}"
    fi
done <<< "$STAGED_STRINGS"

if [ ${#FIXED_FILES[@]} -gt 0 ]; then
    echo "✅ Fixed ellipsis sequences in ${#FIXED_FILES[@]} file(s):"
    for file in "${FIXED_FILES[@]}"; do
        echo "  ${file}"
    done
fi
