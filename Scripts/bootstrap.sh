#!/bin/bash

set -euo pipefail

mint bootstrap

mint run xcodegen xcodegen
echo "✅ Bootstrapped!"

# Check Xcode version matches .xcode-version
# handle script being called from repo root or Scripts folder
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
repo_root=$(dirname "$script_dir")
xcode_version_file="$repo_root/.xcode-version"

if [ ! -f "$xcode_version_file" ]; then
    echo "❌ .xcode-version file not found"
    exit 1
fi

required_version=$(cat "$xcode_version_file")
current_version=$(system_profiler SPDeveloperToolsDataType | grep "Xcode:" | awk '{print $2}')
if [ -z "$current_version" ]; then
    echo "❌ Could not determine current Xcode version. Is Xcode installed?"
    exit 1
fi

if [ "$current_version" != "$required_version" ]; then
    echo "🟡 Xcode version mismatch!"
    echo "Required version: $required_version"
    echo "Current version: $current_version"
    exit 0
fi

echo "✅ Xcode version $current_version matches required version"
