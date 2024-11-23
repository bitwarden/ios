#!/usr/bin/env bash
#
# Builds the Bitwarden iOS app.
# If run in Simulator mode, produces an APP file for the iOS Simulator for ease of automated testing.
# If run in Device mode, produces an IPA file that can be uploaded to Testflight.
#
# Usage:
#
#   $ ./build.sh <build_mode>
#
# Where mode is one of:
#   - Device: Build for physical iOS devices
#   - Simulator: Build for iOS Simulator

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -lt 1 ]; then
  echo >&2 "Called without necessary arguments: ${bold}mode${normal}"
  echo >&2 "For example: \`Scripts/build.sh Simulator"
  exit 1
fi

MODE=$1

BUILD_DIR="build"
DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"
ARCHIVE_PATH="${BUILD_DIR}/Bitwarden.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Bitwarden"

echo "🧱 Building in ${bold}$(pwd)${normal}"
echo "🧱 Using build mode of ${bold}${MODE}${normal}."
echo "🧱 Derived Data path ${bold}${DERIVED_DATA_PATH}${normal}"
echo "🧱 Archive path ${bold}${ARCHIVE_PATH}${normal}"
echo "🧱 Export path ${bold}${EXPORT_PATH}${normal}"
echo ""

echo "🌱 Generating Xcode project"
mint run xcodegen
echo ""

mkdir -p "${BUILD_DIR}"

if [[ "$MODE" == "Simulator" ]]; then
  echo "🔨 Performing Xcode build"
  xcrun xcodebuild \
    -project Bitwarden.xcodeproj \
    -scheme Bitwarden \
    -configuration Debug \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    | xcbeautify --renderer github-actions
else
  echo "📦 Performing Xcode archive"
  xcrun xcodebuild archive \
    -project Bitwarden.xcodeproj \
    -scheme Bitwarden \
    -configuration Release \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -archivePath "${ARCHIVE_PATH}" \
    | xcbeautify --renderer github-actions

  echo "🚚 Performing Xcode archive export"
  xcrun xcodebuild -exportArchive \
    -archivePath "${ARCHIVE_PATH}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -exportPath "${EXPORT_PATH}" \
    -exportOptionsPlist "Configs/export_options.plist" \
    | xcbeautify --renderer github-actions

fi

echo ""
echo "🎉 Build complete"
