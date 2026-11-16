#!/usr/bin/env bash
#
# Fails if a built app contains code that must only exist in Debug builds. It searches every file
# of the app (main binary, frameworks, extensions) for the names of debug-only Swift types without
# launching it.
#
# Usage:
#
#   $ ./Scripts/check-release-binary.sh <path>
#
# Where:
#   - path: An .app, or a directory containing built apps (e.g. an archive's Products/Applications).
#
# Example:
#   $ ./Scripts/check-release-binary.sh build/Bitwarden.xcarchive/Products/Applications

set -euo pipefail

# Swift types that are only compiled into Debug builds. A type's name is stored in its runtime
# metadata, so it stays in an optimized, stripped binary. String literals don't: the optimizer
# inlines short ones into instructions.
DEBUG_ONLY_TYPES=("DebugAppStateResetter")

if [ $# -lt 1 ] || [ ! -d "$1" ]; then
  echo >&2 "❌ Pass the path of a built app or of a directory containing built apps."
  exit 1
fi

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &> /dev/null && pwd)

found=false
for type in "${DEBUG_ONLY_TYPES[@]}"; do
  # A renamed or deleted type would make this check pass without checking anything.
  if ! git -C "$repo_root" grep -qE "(struct|class|enum|actor) $type([^A-Za-z0-9_]|\$)" -- '*.swift'; then
    echo >&2 "❌ '$type' isn't declared in the source any more. Update DEBUG_ONLY_TYPES in $0."
    exit 1
  fi
  matches=$(grep -rlaF -- "$type" "$1" || true)
  if [ -n "$matches" ]; then
    found=true
    echo >&2 "❌ Debug-only type '$type' found in:"
    echo >&2 "$matches"
  fi
done

if [ "$found" = true ]; then
  echo >&2 "This build was compiled with DEBUG defined and must not be distributed."
  exit 1
fi

echo "✅ No debug-only types found in $1"
