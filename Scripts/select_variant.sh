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

entitlements_file="Bitwarden/Application/Support/Bitwarden.entitlements"
extension_entitlements_file="BitwardenActionExtension/Application/Support/BitwardenActionExtension.entitlements"
autofill_entitlements_file="BitwardenAutoFillExtension/Application/Support/BitwardenAutoFill.entitlements"
share_entitlements_file="BitwardenShareExtension/Application/Support/BitwardenShareExtension.entitlements"

echo "🔏 Updating entitlements files"

case $variant in
    Production)
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${extension_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${extension_entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${autofill_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${autofill_entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${share_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden" ]' "${share_entitlements_file}"
        ;;
    Beta)
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${extension_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${extension_entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${autofill_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${autofill_entitlements_file}"
        plutil -replace 'com\.apple\.security\.application-groups' -json '[ "group.$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${share_entitlements_file}"
        plutil -replace 'keychain-access-groups' -json '[ "$(AppIdentifierPrefix)$(ORGANIZATION_IDENTIFIER).bitwarden.beta" ]' "${share_entitlements_file}"
        ;;
esac

echo "⚙️ Updating local config"

local_xcconfig_file="Configs/Local.xcconfig"

case $variant in
    Production)
    ios_bundle_id='$(ORGANIZATION_IDENTIFIER).bitwarden'
    profile_prefix="Dist:"
    app_icon="AppIcon"
        ;;
    Beta)
    ios_bundle_id='$(ORGANIZATION_IDENTIFIER).bitwarden.beta'
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
PROVISIONING_PROFILE_SPECIFIER = ${profile_prefix} Bitwarden
PROVISIONING_PROFILE_SPECIFIER_ACTION_EXTENSION = ${profile_prefix} Extension
PROVISIONING_PROFILE_SPECIFIER_AUTOFILL_EXTENSION = ${profile_prefix} Autofill
PROVISIONING_PROFILE_SPECIFIER_SHARE_EXTENSION = ${profile_prefix} Share Extension
PROVISIONING_PROFILE_SPECIFIER_WATCH_APP = ${profile_prefix} Bitwarden Watch App
EOF

