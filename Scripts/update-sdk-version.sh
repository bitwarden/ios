#!/bin/bash

# Update SDK revision in project-common.yml

set -euo pipefail

if [ $# -lt 3 ]; then
    echo "Usage: $0 <sdk-package> <sdk-swift-ref> <sdk-version>"
    echo "Example: $0 BitwardenSdk 2a6609428275c758fcda5383bfb6b3166ec29eda 1.0.0-281-a1611ee"
    exit 1
fi

SDK_PACKAGE="$1"
SDK_SWIFT_REF="$2"
SDK_VERSION="$3"
FILE="project-common.yml"

echo "🔧 Updating revision in $FILE..."
yq -i ".packages[\"$SDK_PACKAGE\"].revision = \"$SDK_SWIFT_REF\" | .packages[\"$SDK_PACKAGE\"].revision line_comment = \"$SDK_VERSION\"" "$FILE"
echo "✅ Updated revision line:"
grep -A 3 "$SDK_PACKAGE:" "$FILE"
