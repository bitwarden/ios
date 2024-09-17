#!/usr/bin/env bash
#
# Updates the Release version of the Bitwarden app to a build variant
#
# Usage:
#
#   $ ./select_variant.sh <variant>

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -ne 1 ]; then
  echo >&2 "Called without necessary arguments: ${bold}Variant${normal}."
  echo >&2 "For example: \`Scripts/select_variant.sh Beta."
  exit 1
fi

variant=$1

echo "🧱 Setting build variant to ${bold}${variant}${normal}."

local_xcconfig_file="Configs/Local.xcconfig"
export_options_file="Configs/export_options.plist"

case $variant in
    Production)
    ios_bundle_id='com.8bit.bitwarden'
    shared_app_group_id='group.com.bitwarden.bitwarden-authenticator'
    profile_prefix="Dist:"
    app_icon="AppIcon"
        ;;
    Beta)
    ios_bundle_id='com.8bit.bitwarden.beta'
    shared_app_group_id='group.com.bitwarden.bitwarden-authenticator.beta'
    profile_prefix="Dist: Beta"
    app_icon="AppIcon-Beta"
        ;;
esac

cat << EOF > ${local_xcconfig_file}
CODE_SIGN_STYLE = Manual
CODE_SIGN_IDENTITY = Apple Distribution
DEVELOPMENT_TEAM = LTZ2PFU5D6
ORGANIZATION_IDENTIFIER = com.8bit
BASE_BUNDLE_ID = ${ios_bundle_id}
SHARED_APP_GROUP_IDENTIFIER = ${shared_app_group_id}
APPICON_NAME = ${app_icon}
PROVISIONING_PROFILE_SPECIFIER = ${profile_prefix} Bitwarden
PROVISIONING_PROFILE_SPECIFIER_ACTION_EXTENSION = ${profile_prefix} Extension
PROVISIONING_PROFILE_SPECIFIER_AUTOFILL_EXTENSION = ${profile_prefix} Autofill
PROVISIONING_PROFILE_SPECIFIER_SHARE_EXTENSION = ${profile_prefix} Share Extension
PROVISIONING_PROFILE_SPECIFIER_WATCH_APP = ${profile_prefix} Bitwarden Watch App
PROVISIONING_PROFILE_SPECIFIER_WATCH_WIDGET_EXTENSION = ${profile_prefix} Bitwarden Watch Widget Extension
EOF

cat << EOF > ${export_options_file}
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${ios_bundle_id}</key>
        <string>${profile_prefix} Bitwarden</string>
        <key>${ios_bundle_id}.find-login-action-extension</key>
        <string>${profile_prefix} Extension</string>
        <key>${ios_bundle_id}.autofill</key>
        <string>${profile_prefix} Autofill</string>
        <key>${ios_bundle_id}.share-extension</key>
        <string>${profile_prefix} Share Extension</string>
        <key>${ios_bundle_id}.watchkitapp</key>
        <string>${profile_prefix} Bitwarden Watch App</string>
        <key>${ios_bundle_id}.watchkitapp.widget-extension</key>
        <string>${profile_prefix} Bitwarden Watch Widget Extension</string>
    </dict>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF
