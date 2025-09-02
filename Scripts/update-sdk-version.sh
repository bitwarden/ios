#!/bin/bash

# Script to update SDK version in project-common.yml
# Usage: ./Scripts/update-sdk-version.sh <sdk-package> <sdk-version>
# ./Scripts/update-sdk-version.sh BitwardenSdk 2a6609428275c758fcda5383bfb6b3166ec29eda

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <sdk-package> <sdk-version>"
    echo "Example: $0 BitwardenSdk 2a6609428275c758fcda5383bfb6b3166ec29eda"
    exit 1
fi

SDK_PACKAGE="$1"
SDK_VERSION="$2"
FILES=(
  "project-common.yml"
)

for file in "${FILES[@]}"; do
    if [[ -f "$file" ]]; then
        echo "🔧 Updating revision in $file..."
        yq -i ".packages[\"$SDK_PACKAGE\"].revision = \"$SDK_VERSION\"" "$file"
        echo "✅ Updated revision line:"
        grep "revision:" "$file"
    else
        echo "⚠️  Skipping missing file: $file"
    fi
done
