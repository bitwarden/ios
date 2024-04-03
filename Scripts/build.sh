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

if [ $# -ne 2 ]; then
  echo >&2 "Called without necessary arguments: ${bold}Project_Dir${normal} ${bold}Build_Number${normal}."
  echo >&2 "For example: \`Scripts/build.sh . 100\`."
  exit 1
fi

PROJECT_DIR=$1
BUILD_NUMBER=$2

BUILD_DIR="build"

ARCHIVE_PATH="${BUILD_DIR}/Bitwarden.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Bitwarden"

pushd "${PROJECT_DIR}"
echo "🧱 Building in $(pwd)"
echo ""

echo "🌱 Generating xcode project"
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