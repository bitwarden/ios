#!/bin/sh
# CI Build Info Updater
#
# Updates the CIBuildInfo.swift file with additional info from the CI build.
#
# Prerequisites:
#   - Git command line tools installed
#   - Write access to CIBuildInfo.swift file

set -euo pipefail

if [ $# -ne 5 ]; then
    echo "Usage: $0 <repository> <branch> <commit_hash> <ci_run_url> <compiler_flags>"
    echo "E.g: $0 bitwarden/ios main abc123 https://github.com/bitwarden/ios/actions/runs/123 \"DEBUG_MENU FEATURE1\""
    exit 1
fi

set -euo pipefail

repository=$1
branch=$2
commit_hash=$3
ci_run_url=$4
compiler_flags=${5:-''}

ci_build_info_file="BitwardenShared/Core/Platform/Utilities/CIBuildInfo.swift"
git_source="${repository}/${branch}@${commit_hash}"

echo "🧱 Updating app CI Build info..."
echo "🧱 :seedling: ${git_source}"
echo "🧱 :octocat: ${ci_run_url}"
echo "🧱 :hammer_and_wrench: ${compiler_flags}"


cat << EOF > ${ci_build_info_file}
enum CIBuildInfo {
    static let info: KeyValuePairs<String, String> = [
        ":seedling:": "${repository}/${branch} @ ${repository}/${branch}@${commit_hash}",
        ":octocat:": "${ci_run_url}",
        ":hammer_and_wrench:": "${compiler_flags}",
    ]
}
EOF

echo "✅ CI Build info updated successfully."
