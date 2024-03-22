#!/usr/bin/env bash
#
# Builds the beta Bitwarden iOS app, and outputs an IPA file that can be uploaded to TestFlight.
#
# Usage:
#
#   $ ./build.sh <project_dir> <version number> <build number>

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -ne 5 ]; then
  echo >&2 "Called without necessary arguments: ${bold}Project_Dir${normal} ${bold}Local_xcconfig_path${normal} ${bold}Export_options_path${normal} ${bold}Version_Number${normal} {$bold}Build_Number${normal}."
  echo >&2 "For example: \`Scripts/build.sh . resources/Local.xcconfig resources/export_options.plist 2024.1.1 100\`."
  exit 1
fi

PROJECT_DIR=$1
LOCAL_XCCONFIG_PATH=$2
EXPORT_OPTIONS_PATH=$3
VERSION_NUMBER=$4
BUILD_NUMBER=$5

BUILD_DIR="build"

ARCHIVE_PATH="${BUILD_DIR}/Bitwarden.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Bitwarden"

pushd "${PROJECT_DIR}"
echo "Building in $(pwd)"
echo ""

mkdir -p "${BUILD_DIR}"

cp "${LOCAL_XCCONFIG_PATH}" "Configs/Local.xcconfig"

echo "🔨 Performing Xcode archive"
xcrun xcodebuild archive \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  MARKETING_VERSION="${VERSION_NUMBER}" \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
  | xcbeautify --renderer github-actions
echo ""

echo "📦 Performing Xcode archive export"
xcrun xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PATH}" \
  | xcbeautify --renderer github-actions

echo "🎉 Build complete"