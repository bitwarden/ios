#!/usr/bin/env bash
#
# Builds the beta Bitwarden iOS app, and outputs an IPA file that can be uploaded to TestFlight.
#
# Usage:
#
#   $ ./build.sh

set -euo pipefail

BUILD_DIR="build"

ARCHIVE_PATH="${BUILD_DIR}/Bitwarden.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Bitwarden"

echo "🧱 Building in $(pwd)"
echo "🧱 Archive path ${ARCHIVE_PATH}"
echo "🧱 Export path ${EXPORT_PATH}"
echo ""

echo "🌱 Generating Xcode project"
mint run xcodegen

mkdir -p "${BUILD_DIR}"

echo "🔨 Performing Xcode archive"
xcrun xcodebuild archive \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  | xcbeautify --renderer github-actions
echo ""

echo "📦 Performing Xcode archive export"
xcrun xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "Configs/export_options.plist" \
  | xcbeautify --renderer github-actions

echo "🎉 Build complete"
