#!/usr/bin/env bash
#
# Updates the test local config setting the compiler flags.
#
# Usage:
#
#   $ ./Scripts/update_test_local_config.sh "<compiler_flags>"
# Example:
#  $ ./Scripts/update_test_local_config.sh DEBUG_MENU
#  $ ./Scripts/update_test_local_config.sh "FEATURE1 FEATURE2"

set -euo pipefail

bold=$(tput -T ansi bold)
normal=$(tput -T ansi sgr0)

if [ $# -lt 1 ]; then
  echo "🧱 No compiler flags to update test local config."
  exit 0
fi

compiler_flags=${1:-''}

echo "🧱 Updating Test local config..."
echo "🛠️ Compiler flags: ${compiler_flags}"

local_xcconfig_file="Configs-bwa/Local.xcconfig"

cat << EOF > ${local_xcconfig_file}
BITWARDEN_FLAGS = \$(inherited) ${compiler_flags}
EOF

echo "✅ Test local config updated successfully."
