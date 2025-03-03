#!/usr/bin/env bash
#
# Builds the Authenticator iOS app, and outputs an IPA file that can be uploaded to TestFlight.
#
# Usage:
#
#   $ ./build.sh

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

BUILD_DIR="build"

ARCHIVE_PATH="${BUILD_DIR}/Authenticator.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Authenticator"

echo "🧱 Building in $(pwd)"
echo ""

echo "🌱 Generating xcode project"
mint run xcodegen --spec "project-bwa.yml"

mkdir -p "${BUILD_DIR}"

echo "🔨 Performing Xcode archive"
xcrun xcodebuild archive \
  -project Authenticator.xcodeproj \
  -scheme Authenticator \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  | xcbeautify --renderer github-actions
echo ""

echo "📦 Performing Xcode archive export"
xcrun xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "Configs-bwa/export_options.plist" \
  | xcbeautify --renderer github-actions

echo "🎉 Build complete"
