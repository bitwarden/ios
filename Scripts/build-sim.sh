#!/usr/bin/env bash
#
# Builds the beta Bitwarden iOS app in Debug mode for the iOS Simulator, for ease of automated testing.
#
# Usage:
#
#   $ ./build-sim.sh

set -euo pipefail

BUILD_DIR="build"
DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"

echo "🧱 Building in $(pwd)"
echo "🧱 Derived Data path ${DERIVED_DATA_PATH}"
echo ""

echo "🌱 Generating Xcode project"
mint run xcodegen

mkdir -p "${BUILD_DIR}"

echo "🔨 Performing Xcode build"
xcrun xcodebuild \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -configuration Debug \
  -destination "platform=iOS Simulator,OS=18.1,name=iPhone 16" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  | xcbeautify --renderer github-actions

echo "🎉 Build complete"
