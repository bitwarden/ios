#!/usr/bin/env bash
#
# Configures the provisioning profiles for a given variant.
#
# Usage:
#
#   $ ./configure_provisioning_profiles.sh <variant>

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -ne 1 ]; then
  echo >&2 "Called without necessary arguments: ${bold}Variant${normal}."
  echo >&2 "For example: \`Scripts/configure_provisioning_profiles.sh Beta"
  exit 1
fi

variant=$1

echo "🧱 Configure provisioning profiles on ${bold}${variant}${normal}."

case $variant in
    Production)
    profile_prefix="dist_"
        ;;
    Beta)
    profile_prefix="dist_beta_"
        ;;
esac

profiles_dir_path=$HOME/Library/MobileDevice/Provisioning\ Profiles

mkdir -p "$profiles_dir_path"

profiles=(
    "autofill"
    "bitwarden"
    "extension"
    "share_extension"
    "bitwarden_watch_app"
    "bitwarden_watch_app_extension"
)

for file in "${profiles[@]}"
do
    profile_path=$HOME/secrets/$profile_prefix$file.mobileprovision
    profile_uuid=$(grep UUID -A1 -a $profile_path | grep -io "[-A-F0-9]\{36\}")
    cp $profile_path "$profiles_dir_path/$profile_uuid.mobileprovision"
done
