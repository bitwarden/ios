#!/usr/bin/env bash
#
# Builds the Bitwarden iOS app.
# If run in Simulator mode, produces an APP file for the iOS Simulator for ease of automated testing.
# If run in Device mode, produces an IPA file that can be uploaded to TestFlight.
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
mint run xcodegen --spec "project-pm.yml"
echo ""

mkdir -p "${BUILD_DIR}"

case "$MODE" in
  "Simulator")
    echo "🔨 Performing Xcode build"
    xcrun xcodebuild \
      -project Bitwarden.xcodeproj \
      -scheme Bitwarden \
      -configuration Debug \
      -destination "generic/platform=iOS Simulator" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath BitwardenTests.xcresult \
      | xcbeautify --renderer github-actions
    ;;
  "Device")
    echo "📦 Performing Xcode archive"
    xcrun xcodebuild archive \
      -project Bitwarden.xcodeproj \
      -scheme Bitwarden \
      -configuration Release \
      -archivePath "${ARCHIVE_PATH}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath BitwardenTests.xcresult \
      | xcbeautify --renderer github-actions

    echo "🚚 Performing Xcode archive export"
    xcrun xcodebuild -exportArchive \
      -archivePath "${ARCHIVE_PATH}" \
      -exportPath "${EXPORT_PATH}" \
      -exportOptionsPlist "Configs/export_options.plist" \
      -resultBundlePath BitwardenTests.xcresult \
      | xcbeautify --renderer github-actions
    ;;
  *)
    echo >&2 "Invalid build mode: ${bold}${MODE}${normal}"
    echo >&2 "Must be one of: Simulator, Device"
    exit 1
    ;;
esac

echo ""
echo "🎉 Build complete"
