#!/bin/bash
#
# Script to run SwiftLint and SwiftFormat on changed Swift files
# Can be used standalone or as a git pre-commit hook
# Usage: ./Scripts/lint-changes.sh [--fix]

set -euo pipefail

# Track failures
SWIFTFORMAT_FAILED=0
SWIFTLINT_FAILED=0

# Parse command line arguments
FIX_MODE=false
if [ "${1:-}" == "--fix" ]; then
    FIX_MODE=true
fi

# Staged files only when running as pre-commit hook, all changed files when standalone
DIFF_ARGS=$( [ -n "${GIT_INDEX_FILE:-}" ] && echo "--cached" || echo "HEAD" )
SWIFT_FILES=$(git diff --name-only $DIFF_ARGS --diff-filter=ACMR | grep "\.swift$" || true)

# Exit early if no Swift files changed
if [ -z "$SWIFT_FILES" ]; then
    echo "No Swift files to lint"
    exit 0
fi

# Convert file list to array
FILE_ARRAY=()
while IFS= read -r file; do
    if [ -f "$file" ]; then
        FILE_ARRAY+=("$file")
    fi
done <<< "$SWIFT_FILES"

# Exit if no valid files found
if [ ${#FILE_ARRAY[@]} -eq 0 ]; then
    echo "No Swift files to lint"
    exit 0
fi

if [ "$FIX_MODE" = true ]; then
    echo "Formatting and linting ${#FILE_ARRAY[@]} Swift file(s)..."
else
    echo "Checking format and linting ${#FILE_ARRAY[@]} Swift file(s)..."
fi

for file in "${FILE_ARRAY[@]}"; do
    echo "  $file"
done

# Run SwiftFormat
echo ""
echo "Running SwiftFormat..."
if [ "$FIX_MODE" = true ]; then
    # Format files
    if ! mint run swiftformat --quiet "${FILE_ARRAY[@]}"; then
        echo "❌ SwiftFormat failed"
        SWIFTFORMAT_FAILED=1
    fi
else
    # Check formatting without modifying files
    if ! mint run swiftformat --lint "${FILE_ARRAY[@]}"; then
        echo "❌ SwiftFormat found formatting issues"
        SWIFTFORMAT_FAILED=1
    fi
fi

# Run SwiftLint
echo ""
echo "Running SwiftLint..."
if [ "$FIX_MODE" = true ]; then
    mint run swiftlint lint --quiet --fix "${FILE_ARRAY[@]}" || true

    # Re-run in check mode to surface any violations that couldn't be auto-fixed
    echo ""
    echo "Checking for remaining SwiftLint issues..."
    if ! mint run swiftlint lint --strict "${FILE_ARRAY[@]}"; then
        echo "⚠️  Some issues require manual fixes (see above)"
        SWIFTLINT_FAILED=1
    fi
else
    if ! mint run swiftlint lint --quiet --strict "${FILE_ARRAY[@]}"; then
        echo "❌ SwiftLint found issues in modified files"
        SWIFTLINT_FAILED=1
    fi
fi

# Report results
echo ""
if [ $SWIFTFORMAT_FAILED -eq 1 ] || [ $SWIFTLINT_FAILED -eq 1 ]; then
    if [ "$FIX_MODE" = false ]; then
        echo "To auto-fix, run:"
        echo "  ./Scripts/lint-changes.sh --fix"
    fi
    exit 1
fi

if [ "$FIX_MODE" = true ]; then
    echo "✅ All files formatted and all fixable issues corrected"
else
    echo "✅ All modified Swift files passed formatting and linting checks"
fi
exit 0
