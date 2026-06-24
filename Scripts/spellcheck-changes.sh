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

# Convert file list to array, filtering excluded paths
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

# Filter out excluded paths:
#   - Files under *.xcassets/ folders
#   - Files under AppIcon-*.icon/ folders
#   - Files under BitwardenResources/Fonts/
FILTERED_FILES=()
for file in "${FILE_ARRAY[@]}"; do
    if [[ "$file" == *.xcassets/* ]] || \
       [[ "$file" =~ AppIcon-[^/]*\.icon/ ]] || \
       [[ "$file" == BitwardenResources/Fonts/* ]]; then
        continue
    fi
    FILTERED_FILES+=("$file")
done

# Exit if all files were filtered out
if [ ${#FILTERED_FILES[@]} -eq 0 ]; then
    echo "No changed files to spell check"
    exit 0
fi

# Split into Localizable.* files (diff-only check) vs regular files
LOCALIZABLE_FILES=()
REGULAR_FILES=()
for file in "${FILTERED_FILES[@]}"; do
    basename=$(basename "$file")
    if [[ "$basename" == Localizable.* ]]; then
        LOCALIZABLE_FILES+=("$file")
    else
        REGULAR_FILES+=("$file")
    fi
done

echo "Running spell check on ${#FILTERED_FILES[@]} file(s)..."
for file in "${FILTERED_FILES[@]}"; do
    echo "  $file"
done
echo ""

FOUND_ERRORS=0

# Run typos on regular files
if [ ${#REGULAR_FILES[@]} -gt 0 ]; then
    typos "${REGULAR_FILES[@]}" || FOUND_ERRORS=1
fi

# For Localizable.* files, only check added/changed lines from the diff
if [ ${#LOCALIZABLE_FILES[@]} -gt 0 ]; then
    TMPFILE=$(mktemp /tmp/spellcheck-diff.XXXXXX)
    trap 'rm -f "$TMPFILE"' EXIT

    for file in "${LOCALIZABLE_FILES[@]}"; do
        if [ -n "$GIT_INDEX_FILE" ]; then
            DIFF=$(git diff --cached -U0 -- "$file" 2>/dev/null)
        else
            DIFF=$(git diff -U0 HEAD -- "$file" 2>/dev/null)
        fi
        # Extract only added lines (skip the +++ file header line)
        ADDED=$(echo "$DIFF" | grep '^+' | grep -v '^+++' | sed 's/^+//')
        if [ -z "$ADDED" ]; then
            continue
        fi
        echo "$ADDED" > "$TMPFILE"
        typos "$TMPFILE" || FOUND_ERRORS=1
    done
fi

if [ $FOUND_ERRORS -eq 0 ]; then
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
