#!/usr/bin/env bash
#
# Updates the Release version of the Authenticator app to a build variant
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
    ios_bundle_id='com.bitwarden.authenticator'
    profile_prefix="Dist:"
    app_icon="AppIcon"
        ;;
    Beta)
    ios_bundle_id='com.bitwarden.autenticator'
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
APPICON_NAME = ${app_icon}
PROVISIONING_PROFILE_SPECIFIER = ${profile_prefix} Bitwarden Authenticator
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
        <string>${profile_prefix} Bitwarden Authenticator</string>
    </dict>
    <key>manageAppVersionAndBuildNumber</key>
    <false/>
</dict>
</plist>
EOF
