#!/usr/bin/env bash
#
# Pre-processes the codebase before an audit-build-warnings run.
# Runs SwiftFormat and SwiftLint --fix, then a second SwiftFormat pass to
# clean up any formatting drift introduced by SwiftLint fixes.
#
# Prints a structured summary block so Claude can report auto-fix counts.
#
# Usage:
#
#   $ ./Scripts/audit-build-warnings-prep.sh

set -euo pipefail

echo "=== Phase 0: Pre-process ==="
echo ""

echo "SwiftFormat (pass 1)..."
SF1_OUTPUT=$(mint run swiftformat . 2>&1)
echo "$SF1_OUTPUT"
SF1_SUMMARY=$(echo "$SF1_OUTPUT" | grep -E "SwiftFormat completed" | tail -1 || echo "SwiftFormat completed. 0 files updated.")

echo ""
echo "SwiftLint --fix..."
SL_OUTPUT=$(mint run swiftlint --fix . 2>&1)
echo "$SL_OUTPUT"
SL_SUMMARY=$(echo "$SL_OUTPUT" | grep -E "^Done correcting|^No correctable" | tail -1 || echo "Done correcting 0 files.")

echo ""
echo "SwiftFormat (pass 2 — drift cleanup)..."
SF2_OUTPUT=$(mint run swiftformat . 2>&1)
echo "$SF2_OUTPUT"
SF2_SUMMARY=$(echo "$SF2_OUTPUT" | grep -E "SwiftFormat completed" | tail -1 || echo "SwiftFormat completed. 0 files updated.")

echo ""
echo "=== autofix-summary ==="
echo "swiftformat_pass1: $SF1_SUMMARY"
echo "swiftlint_fix:     $SL_SUMMARY"
echo "swiftformat_pass2: $SF2_SUMMARY"
echo "=== end-autofix-summary ==="
