#!/bin/sh
# CI Build Info Updater
#
# Updates the CIBuildInfo.swift file with additional info from the CI build.
#
# Prerequisites:
#   - Git command line tools installed
#   - Write access to CIBuildInfo.swift file

set -euo pipefail

if [ $# -ne 6 ]; then
    echo >&2 "Called with $# arguments but expected 6."
    echo "Usage: $0 <repository> <branch> <commit_hash> <ci_run_number> <ci_run_attempt> <compiler_flags>"
    echo "E.g: $0 bitwarden/ios main abc123 1234567890 1 \"DEBUG_MENU FEATURE1\""
    exit 1
fi

repository=$1
branch=$2
commit_hash=$3
ci_run_number=$4
ci_run_attempt=$5
compiler_flags=${6:-''}

ci_build_info_file="BitwardenShared/Core/Platform/Utilities/CIBuildInfo.swift"
git_source="${repository}/${branch}@${commit_hash}"
ci_run_source="${repository}/actions/runs/${ci_run_number}/attempts/${ci_run_attempt}"

echo "🧱 Updating app CI Build info..."
echo "🧱 🧱 Commit: ${git_source}"
echo "🧱 💻 Build Source: ${ci_run_source}"
echo "🧱 🛠️ Compiler Flags: ${compiler_flags}"


cat << EOF > ${ci_build_info_file}
enum CIBuildInfo {
    static let info: KeyValuePairs<String, String> = [
        "🧱 Commit": "${git_source}",
        "💻 Build Source": "${ci_run_source}",
        "🛠️ Compiler Flags": "${compiler_flags}",
    ]
}
EOF
echo "✅ CI Build info updated successfully."
