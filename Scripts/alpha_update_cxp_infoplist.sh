#!/usr/bin/env bash
#
# Updates the Info.plist from Bitwarden Autofill extension to support Credential Exchange.
#
# :warning: Note: This script should be removed when we're ready to relase CXP to production.
#
# Usage:
#
#   $ ./Scripts/alpha_update_cxp_infoplist.sh

set -euo pipefail

autofill_info_plist_path="BitwardenAutoFillExtension/Application/Support/Info.plist"
app_info_plist_path="Bitwarden/Application/Support/Info.plist"

if ! grep -q "SupportsCredentialExchange" $autofill_info_plist_path; then
  plutil -insert NSExtension.NSExtensionAttributes.ASCredentialProviderExtensionCapabilities.SupportsCredentialExchange -bool YES $autofill_info_plist_path
  plutil -insert NSExtension.NSExtensionAttributes.ASCredentialProviderExtensionCapabilities.SupportedCredentialExchangeVersions -array $autofill_info_plist_path
  plutil -insert NSExtension.NSExtensionAttributes.ASCredentialProviderExtensionCapabilities.SupportedCredentialExchangeVersions.0 -string "1.0" $autofill_info_plist_path
fi

if ! grep -q "ASCredentialExchangeActivityType" $app_info_plist_path; then
  if ! grep -q "NSUserActivityTypes" $app_info_plist_path; then
    plutil -insert NSUserActivityTypes -array $app_info_plist_path
  fi
  plutil -insert NSUserActivityTypes -string ASCredentialExchangeActivityType -append $app_info_plist_path
fi
