#!/bin/bash
#
# Updates the version number stored in Settings.bundle to match the version in Xcode.

set -e

SETTINGS_BUNDLE_PATH="${CODESIGNING_FOLDER_PATH}/Settings.bundle/Root.plist"
BUILD_STRING="${MARKETING_VERSION} (${CURRENT_PROJECT_VERSION})"

/usr/libexec/PlistBuddy -c "Set PreferenceSpecifiers:0:DefaultValue $BUILD_STRING" "${SETTINGS_BUNDLE_PATH}"
