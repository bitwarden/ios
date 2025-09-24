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

# Show file status
ls -l "$PACKAGE_RESOLVED" || echo "❌ File not found: $PACKAGE_RESOLVED"

CURRENT_SDK_SWIFT_BLOCK=$(jq -r '.pins[] | select(.identity == "sdk-swift")' "$PACKAGE_RESOLVED")
echo "🔎 Current sdk_swift block Package.resolved:"
echo $CURRENT_SDK_SWIFT_BLOCK

# Extract current hash
CURRENT_HASH=$(jq -r '.pins[] | select(.identity == "sdk-swift") | .state.revision' "$PACKAGE_RESOLVED")
echo "🔎 Current hash in Package.resolved: $CURRENT_HASH"
echo "🔁 Target replacement hash: $SDK_SWIFT_REF"

# Validate extracted value
if [ -z "$CURRENT_HASH" ]; then
    echo "::error::❌ Could not extract current hash with jq — check input file format."
    exit 1
fi

# 🔐 Ensure file is writable
if [ ! -w "$PACKAGE_RESOLVED" ]; then
    echo "🔓 File is not writable, attempting chmod +w..."
    chmod +w "$PACKAGE_RESOLVED" || {
        echo "::error::❌ Failed to make $PACKAGE_RESOLVED writable."
        exit 1
    }
else
    echo "✅ $PACKAGE_RESOLVED is writable."
fi

# Create temp file and run jq
TMP_FILE=$(mktemp)
echo "📂 Temp file for jq output: $TMP_FILE"

echo "🛠️ Running jq update..."
jq --arg new "$SDK_SWIFT_REF" '
  .pins |= map(
    if .identity == "sdk-swift" then
      .state.revision = $new
    else
      .
    end
  )
' "$PACKAGE_RESOLVED" > "$TMP_FILE"

JQ_EXIT_CODE=$?
echo "🔚 jq exit code: $JQ_EXIT_CODE"
if [ $JQ_EXIT_CODE -ne 0 ]; then
    echo "::error::❌ jq failed to write to temp file."
    cat "$TMP_FILE" || echo "⚠️ Temp file is empty or corrupted"
    exit 1
fi

# Show jq output for review
CURRENT_SDK_SWIFT_BLOCK=$(jq -r '.pins[] | select(.identity == "sdk-swift")' "$TMP_FILE")
echo "🔎 Current sdk_swift block Package.resolved:"
echo $CURRENT_SDK_SWIFT_BLOCK

# Final check before replacing
if [ ! -s "$TMP_FILE" ]; then
    echo "::error::❌ jq output is empty. Aborting replacement."
    exit 1
fi

# Replace the file
mv "$TMP_FILE" "$PACKAGE_RESOLVED"
echo "✅ Successfully updated revision in $PACKAGE_RESOLVED"
