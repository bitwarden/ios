#!/bin/bash

set -euo pipefail

brew bundle check # use --verbose to list missing dependencies

mint bootstrap

# Handle script being called from repo root or Scripts folder
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
repo_root=$(dirname "$script_dir")

mint run xcodegen --spec "$repo_root/project-bwk.yml"
mint run xcodegen --spec "$repo_root/project-pm.yml"
mint run xcodegen --spec "$repo_root/project-bwa.yml"
mint run xcodegen --spec "$repo_root/project-bwth.yml"
echo "✅ Bootstrapped!"

# Check Xcode version matches .xcode-version
xcode_version_file="$repo_root/.xcode-version"

if [ ! -f "$xcode_version_file" ]; then
    echo "❌ .xcode-version file not found"
    exit 1
fi

required_version=$(cat "$xcode_version_file")
xcode_line=$(xcodebuild -version 2>/dev/null || system_profiler SPDeveloperToolsDataType | grep "Xcode:")
current_version=$(echo "$xcode_line" | head -n 1 | awk '{print $2}')
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
