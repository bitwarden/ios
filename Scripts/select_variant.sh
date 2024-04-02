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

local_xcconfig_file="Configs/Local.xcconfig"

case $variant in
    production)
        ;;
    beta)
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