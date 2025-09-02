#!/usr/bin/env bash
#
# Builds the Bitwarden iOS app.
# If run in Simulator mode, produces an APP file for the iOS Simulator for ease of automated testing.
# If run in Device mode, produces an IPA file that can be uploaded to TestFlight.
#
# Usage:
#
#   $ ./Scripts/build.sh <project_file> <build_scheme> <build_mode>
#
# Where:
#   - project_file: Path to the project file (i.e., project-pm.yml or project-bwa.yml)
#   - build_scheme: Build scheme (i.e., Bitwarden or Authenticator)
#   - build_mode is one of:
#     - Device: Build for physical iOS devices
#     - Simulator: Build for iOS Simulator
#
# Examples:
#   $ ./Scripts/build.sh project-pm.yml Bitwarden Simulator
#   $ ./Scripts/build.sh project-bwa.yml Authenticator Device

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -lt 3 ]; then
  echo >&2 "Called without necessary arguments: ${bold}project_file build_scheme build_mode${normal}"
  echo >&2 "For example: \`Scripts/build.sh project-pm.yml Bitwarden Simulator\`"
  exit 1
fi

PROJECT_FILE=$1
BUILD_SCHEME=$2
MODE=$3

BUILD_DIR="build"
DERIVED_DATA_PATH="${BUILD_DIR}/DerivedData"
ARCHIVE_PATH="${BUILD_DIR}/${BUILD_SCHEME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/${BUILD_SCHEME}"
RESULT_BUNDLE_PATH="export/build.xcresult"
RESULT_EXPORT_ARCHIVE_BUNDLE_PATH="export/buildExportArchive.xcresult"

echo "🧱 Building in ${bold}$(pwd)${normal}"
echo "🧱 Project file ${bold}${PROJECT_FILE}${normal}"
echo "🧱 Build Scheme ${bold}${BUILD_SCHEME}${normal}"
echo "🧱 Using build mode of ${bold}${MODE}${normal}"
echo "🧱 Derived Data path ${bold}${DERIVED_DATA_PATH}${normal}"
echo "🧱 Archive path ${bold}${ARCHIVE_PATH}${normal}"
echo "🧱 Export path ${bold}${EXPORT_PATH}${normal}"
echo ""

echo "🌱 Generating Xcode projects"
mint run xcodegen --spec "project-bwk.yml"
mint run xcodegen --spec "${PROJECT_FILE}"
echo ""

mkdir -p "${BUILD_DIR}"

case "$MODE" in
  "Simulator")
    echo "🔨 Performing Xcode build"
    xcrun xcodebuild \
      -workspace Bitwarden.xcworkspace \
      -scheme "${BUILD_SCHEME}" \
      -configuration Debug \
      -destination "generic/platform=iOS Simulator" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath "${RESULT_BUNDLE_PATH}" \
      -quiet
    ;;
  "Device")
    echo "📦 Performing Xcode archive"
    xcrun xcodebuild archive \
      -workspace Bitwarden.xcworkspace \
      -scheme "${BUILD_SCHEME}" \
      -configuration Release \
      -archivePath "${ARCHIVE_PATH}" \
      -derivedDataPath "${DERIVED_DATA_PATH}" \
      -resultBundlePath "${RESULT_BUNDLE_PATH}" \
      -quiet

    echo "🚚 Performing Xcode archive export"
    xcrun xcodebuild -exportArchive \
      -archivePath "${ARCHIVE_PATH}" \
      -exportPath "${EXPORT_PATH}" \
      -exportOptionsPlist "Configs/export_options.plist" \
      -resultBundlePath "${RESULT_EXPORT_ARCHIVE_BUNDLE_PATH}" \
      -quiet
    ;;
  *)
    echo >&2 "Invalid build mode: ${bold}${MODE}${normal}"
    echo >&2 "Must be one of: Simulator, Device"
    exit 1
    ;;
esac

echo ""
echo "🎉 Build complete"
