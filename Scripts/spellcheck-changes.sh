#!/bin/bash
#
# Script to run spell checking on changed files
# Can be used standalone or as a git pre-commit hook
# Usage: ./Scripts/spellcheck-changes.sh

set -e

# Determine if we're running as a pre-commit hook
if [ -n "$GIT_INDEX_FILE" ]; then
    # Running as pre-commit hook - check staged files
    CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
else
    # Running standalone - check all modified files (staged and unstaged)
    CHANGED_FILES=$(git diff --name-only --diff-filter=ACM HEAD 2>/dev/null || git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
fi

# Exit early if no files changed
if [ -z "$CHANGED_FILES" ]; then
    echo "No changed files to spell check"
    exit 0
fi

# Convert file list to array
FILE_ARRAY=()
while IFS= read -r file; do
    if [ -f "$file" ]; then
        FILE_ARRAY+=("$file")
    fi
done <<< "$CHANGED_FILES"

# Exit if no valid files found
if [ ${#FILE_ARRAY[@]} -eq 0 ]; then
    echo "No changed files to spell check"
    exit 0
fi

echo "Running spell check on ${#FILE_ARRAY[@]} file(s)..."
for file in "${FILE_ARRAY[@]}"; do
    echo "  $file"
done
echo ""

# Run typos
if typos "${FILE_ARRAY[@]}"; then
    echo "✅ No spelling errors found"
    exit 0
else
    echo ""
    echo "❌ Spelling errors found"
    echo ""
    echo "To fix:"
    echo "  1. Correct the spelling manually, OR"
    echo "  2. Run: typos -w <file> to auto-fix, OR"
    echo "  3. Add valid technical terms to .typos.toml"
    echo ""
    echo "Examples:"
    echo "  # Auto-fix all staged files"
    echo "  typos -w \$(git diff --cached --name-only)"
    echo ""
    echo "  # Auto-fix specific file"
    echo "  typos -w path/to/file.swift"
    exit 1
fi
