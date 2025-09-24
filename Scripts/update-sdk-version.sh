#!/bin/bash

# Update SDK revision in project-common.yml and Package.resolved

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <sdk-package> <sdk-swift-ref> <sdk-version>"
    echo "Example: $0 BitwardenSdk 2a6609428275c758fcda5383bfb6b3166ec29eda 1.0.0-281-a1611ee"
    exit 1
fi

SDK_PACKAGE="$1"
SDK_SWIFT_REF="$2"
SDK_VERSION="$3"
PROJECT_FILE="project-common.yml"
PACKAGE_RESOLVED="Bitwarden.xcworkspace/xcshareddata/swiftpm/Package.resolved"

# Update project-common.yml
echo "🔧 Updating revision in $PROJECT_FILE..."
yq -i ".packages[\"$SDK_PACKAGE\"].revision = \"$SDK_SWIFT_REF\" | .packages[\"$SDK_PACKAGE\"].revision line_comment = \"$SDK_VERSION\"" "$PROJECT_FILE"
echo "✅ Updated revision line in $PROJECT_FILE"

# Update Package.resolved
echo "🔧 Updating revision in $PACKAGE_RESOLVED..."
CURRENT_HASH=$(jq -r '.pins[] | select(.identity == "sdk-swift") | .state.revision' "$PACKAGE_RESOLVED")
echo "Current hash in Package.resolved: $CURRENT_HASH"
sed -i.bak "s/$CURRENT_HASH/$SDK_SWIFT_REF/g" "$PACKAGE_RESOLVED"
echo "✅ Updated revision in $PACKAGE_RESOLVED"
