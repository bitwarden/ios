#!/bin/bash
#
# Updates the version number stored in Settings.bundle to match the version in Xcode.

set -e

SETTINGS_BUNDLE_PATH="${CODESIGNING_FOLDER_PATH}/Settings.bundle/Root.plist"
BUILD_VERSION=$(sed -n '/MARKETING_VERSION/{s/MARKETING_VERSION = //;s/;//;s/^[[:space:]]*//;p;q;}' "${PROJECT_FILE_PATH}/project.pbxproj")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")
BUILD_STRING="${BUILD_VERSION} (${BUILD_NUMBER})"

/usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:0:DefaultValue $BUILD_STRING" "${SETTINGS_BUNDLE_PATH}"
