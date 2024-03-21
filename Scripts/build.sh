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

if [ $# -ne 3 ]; then
  echo >&2 "Called without necessary arguments: ${bold}Project_Dir${normal} ${bold}Version_Number${normal} {$bold}Build_Number${normal}."
  echo >&2 "For example: \`Scripts/build.sh . 2024.1.1 100\`."
  exit 1
fi

PROJECT_DIR=$1
VERSION_NUMBER=$2
BUILD_NUMBER=$3

BUILD_DIR="build"

ARCHIVE_PATH="${BUILD_DIR}/Bitwarden.xcarchive"
EXPORT_PATH="${BUILD_DIR}/Bitwarden"
EXPORT_OPTIONS_PATH="${BUILD_DIR}/ExportOptions.plist"

pushd "${PROJECT_DIR}"
echo "Building in $(pwd)"
echo ""

mkdir -p "${BUILD_DIR}"

cat << EOF > "${EXPORT_OPTIONS_PATH}"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.8bit.bitwarden</key>
        <string>Bitwarden Distribution</string>
        <key>com.8bit.bitwarden.find-login-action-extension</key>
        <string>Bitwarden Action Extension Distribution</string>
        <key>com.8bit.bitwarden.autofill</key>
        <string>Bitwarden AutoFill Extension Distribution</string>
        <key>com.8bit.bitwarden.share-extension</key>
        <string>Bitwarden Share Extension Distribution</string>
        <key>com.8bit.bitwarden.watchkitapp</key>
        <string>Bitwarden watchOS Distribution</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution: Bitwarden Inc</string>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF

cat << EOF > Configs/Local.xcconfig
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = Apple Distribution: Bitwarden, Inc.
DEVELOPMENT_TEAM = LTZ2PFU5D6
ORGANIZATION_IDENTIFIER = com.8bit
PROVISIONING_PROFILE_SPECIFIER = Dist: Bitwarden
PROVISIONING_PROFILE_SPECIFIER_ACTION_EXTENSION = Dist: Extension
PROVISIONING_PROFILE_SPECIFIER_AUTOFILL_EXTENSION = Dist: Autofill
PROVISIONING_PROFILE_SPECIFIER_SHARE_EXTENSION = Dist: Share Extension
PROVISIONING_PROFILE_SPECIFIER_WATCH_APP = Dist: Bitwarden Watch App
EOF

echo "Performing Xcode archive"
xcrun xcodebuild archive \
  -project Bitwarden.xcodeproj \
  -scheme Bitwarden \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  MARKETING_VERSION="${VERSION_NUMBER}" \
  CURRENT_PROJECT_VERSION="${BUILD_NUMBER}" \
  | xcbeautify --renderer github-actions
echo ""

echo "Performing Xcode archive export"
xcrun xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_OPTIONS_PATH}" \
  | xcbeautify --renderer github-actions

echo "Build complete 🎉"