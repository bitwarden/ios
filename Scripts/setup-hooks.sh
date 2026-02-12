#!/bin/bash
#
# Script to set up git hooks for the Bitwarden iOS project
# This script is called automatically by bootstrap.sh
# It can also be run manually to re-install hooks

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Get the common git directory (shared across all worktrees)
GIT_DIR="$(git -C "$REPO_ROOT" rev-parse --git-common-dir)"
HOOKS_DIR="$GIT_DIR/hooks"

echo "Setting up git hooks..."

# Ensure .git/hooks directory exists
mkdir -p "$HOOKS_DIR"

# Set up pre-commit hook
PRE_COMMIT_SOURCE="$SCRIPT_DIR/pre-commit"
PRE_COMMIT_TARGET="$HOOKS_DIR/pre-commit"

if [ ! -f "$PRE_COMMIT_SOURCE" ]; then
    echo "❌ Error: pre-commit script not found at $PRE_COMMIT_SOURCE"
    exit 1
fi

# Copy the hook and make it executable
cp "$PRE_COMMIT_SOURCE" "$PRE_COMMIT_TARGET"
chmod +x "$PRE_COMMIT_TARGET"
echo "  ✅ pre-commit hook installed"

echo "✅ Git hooks set up successfully"
