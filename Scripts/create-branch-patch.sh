#!/bin/bash
set -euo pipefail

# Create a patch file of all commits added to the current branch
# Usage: ./create-branch-patch.sh [base-branch]

BASE_BRANCH="${1:-main}"
CURRENT_BRANCH=$(git branch --show-current)

if [ -z "$CURRENT_BRANCH" ]; then
    echo "Error: Not on a branch (detached HEAD?)"
    exit 1
fi

if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ]; then
    echo "Error: Currently on base branch '$BASE_BRANCH'. Switch to a feature branch first."
    exit 1
fi

if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
    echo "Error: Base branch '$BASE_BRANCH' does not exist"
    exit 1
fi

COMMIT_COUNT=$(git rev-list --count "$BASE_BRANCH..HEAD" 2>/dev/null || echo "0")
if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "Error: No commits found between $BASE_BRANCH and $CURRENT_BRANCH"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PATCH_FILE="${CURRENT_BRANCH//\//_}_${TIMESTAMP}.patch"

echo "Creating patch from $BASE_BRANCH..$CURRENT_BRANCH..."
git format-patch "$BASE_BRANCH..HEAD" --stdout > "$PATCH_FILE"

echo "✓ Patch created successfully: $PATCH_FILE"
echo "  Includes $COMMIT_COUNT commit(s) from branch '$CURRENT_BRANCH'"
echo ""
echo "To apply this patch:"
echo "  git apply $PATCH_FILE"
echo "  git am < $PATCH_FILE  # (to apply with commit history)"
