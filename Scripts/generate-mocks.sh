#!/bin/bash
#
# Run Sourcery for a given framework, ensuring BITWARDEN_SDK_PATH is set so that
# the SDK SPM package sources in sourcery.yml can be resolved.
#
# Usage: ./Scripts/generate-mocks.sh [BitwardenShared|AuthenticatorShared|BitwardenKit|AuthenticatorBridgeKit]
#
# Intended to be run as an Xcode build phase script, where $BUILD_DIR and $TARGET_NAME
# are already set in the environment by Xcode. When no framework argument is given,
# TARGET_NAME is used to determine which framework's config to run.
#
# To run standalone, supply BUILD_DIR manually:
#   BUILD_DIR=$(xcodebuild -showBuildSettings \
#     -workspace Bitwarden.xcworkspace -scheme Bitwarden \
#     -disableAutomaticPackageResolution 2>/dev/null \
#     | awk -F ' = ' '/^ *BUILD_DIR = / { sub(/[[:space:]]+$/, "", $2); print $2; exit }') \
#   ./Scripts/generate-mocks.sh
#
# BUILD_DIR = .../DerivedData/Bitwarden-<hash>/Build/Products (regular)
#           = .../DerivedData/Bitwarden-<hash>/Build/Intermediates.noindex/ArchiveIntermediates/... (archive)
# BITWARDEN_SDK_PATH = .../DerivedData/Bitwarden-<hash>/SourcePackages/checkouts/sdk-swift

set -euo pipefail

if [[ ! "$PATH" =~ "/opt/homebrew/bin" ]]; then
    PATH="/opt/homebrew/bin:$PATH"
fi

FRAMEWORK="${1:-${TARGET_NAME:-BitwardenShared}}"
CONFIG="$FRAMEWORK/Sourcery/sourcery.yml"

if [ ! -f "$CONFIG" ]; then
    echo "Error: config not found at $CONFIG"
    exit 1
fi

if [ -z "${BUILD_DIR:-}" ]; then
    echo "⚠️  BUILD_DIR is not set."
    echo "   Run this script from an Xcode build phase, or supply BUILD_DIR manually."
    echo "   See the script header for instructions."
    exit 1
fi

# BUILD_DIR nests at different depths for regular builds vs xcodebuild archive, so
# walk up the directory tree until we find the DerivedData root (contains SourcePackages/).
export BITWARDEN_SDK_PATH
_search_dir="$BUILD_DIR"
BITWARDEN_SDK_PATH=""
while [ "$_search_dir" != "/" ]; do
    if [ -d "$_search_dir/SourcePackages/checkouts/sdk-swift" ]; then
        BITWARDEN_SDK_PATH="$_search_dir/SourcePackages/checkouts/sdk-swift"
        break
    fi
    _search_dir="$(dirname "$_search_dir")"
done

if [ -z "$BITWARDEN_SDK_PATH" ]; then
    echo "error: Could not locate sdk-swift checkout under SourcePackages/ — ensure SPM packages are resolved before running Sourcery."
    exit 1
fi

echo "BITWARDEN_SDK_PATH: $BITWARDEN_SDK_PATH"
mint run sourcery --config "$CONFIG"
