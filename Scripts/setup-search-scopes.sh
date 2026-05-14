#!/bin/bash
#
# Script to install Xcode Search Custom Scopes for the Bitwarden workspace.
# Run manually — not called automatically by bootstrap.sh.
#
# Usage: bash Scripts/setup-search-scopes.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TEMPLATE="$REPO_ROOT/Xcode/SearchScopes/IDEFindNavigatorScopes.plist"
TARGET_DIR="$REPO_ROOT/Bitwarden.xcworkspace/xcuserdata/$(whoami).xcuserdatad"
TARGET="$TARGET_DIR/IDEFindNavigatorScopes.plist"

if [ ! -f "$TEMPLATE" ]; then
    echo "❌ Template not found: $TEMPLATE"
    exit 1
fi

mkdir -p "$TARGET_DIR"

if [ ! -f "$TARGET" ]; then
    cp "$TEMPLATE" "$TARGET"
    echo "✅ Search scopes installed."
    echo "ℹ️  Restart Xcode for the scopes to appear in the Find navigator."
    exit 0
fi

echo "IDEFindNavigatorScopes.plist already exists at:"
echo "  $TARGET"
echo ""
echo "Choose an action:"
echo "  [o] Overwrite — replace with the template (existing custom scopes will be lost)"
echo "  [m] Merge     — add template scopes not already present (matched by name)"
echo "  [c] Cancel    — abort without changes"
echo ""

while true; do
    read -r -p "Enter choice [o/m/c]: " choice
    case "$choice" in
        o|O)
            cp "$TEMPLATE" "$TARGET"
            echo "✅ Search scopes overwritten."
            echo "ℹ️  Restart Xcode for the scopes to appear in the Find navigator."
            exit 0
            ;;
        m|M)
            if ! command -v python3 &> /dev/null; then
                echo "❌ python3 is required for merge but was not found."
                echo "   Try the overwrite option instead, or install Python 3."
                exit 1
            fi
            result=$(python3 - "$TEMPLATE" "$TARGET" <<'PYEOF'
import sys
import plistlib

template_path = sys.argv[1]
target_path = sys.argv[2]

with open(template_path, "rb") as f:
    template_scopes = plistlib.load(f)

with open(target_path, "rb") as f:
    existing_scopes = plistlib.load(f)

existing_names = {s["name"] for s in existing_scopes}
added = 0
skipped = 0

for scope in template_scopes:
    if scope["name"] in existing_names:
        skipped += 1
    else:
        existing_scopes.append(scope)
        added += 1

with open(target_path, "wb") as f:
    plistlib.dump(existing_scopes, f, fmt=plistlib.FMT_XML, sort_keys=False)

print(f"{added} {skipped}")
PYEOF
)
            added=$(echo "$result" | awk '{print $1}')
            skipped=$(echo "$result" | awk '{print $2}')
            echo "✅ Merge complete: added $added scope(s), skipped $skipped (already present)."
            echo "ℹ️  Restart Xcode for the scopes to appear in the Find navigator."
            exit 0
            ;;
        c|C)
            echo "Cancelled. No changes made."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please enter o, m, or c."
            ;;
    esac
done
