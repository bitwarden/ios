#!/bin/sh
#
# Updates the CIBuildInfo.swift file to add any additional info we need from the CI build.
#
# Usage:
#
#   $ ./update_app_ci_build_info.sh <ci_run_id> <ci_run_number> <ci_run_attempt>

set -euo pipefail

if [ $# -ne 3 ]; then
  echo >&2 "Called without necessary arguments."
  echo >&2 "For example: \`Scripts/update_app_ci_build_info.sh 123123 111 1."
  exit 1
fi

ci_run_id=$1
ci_run_number=$2
ci_run_attempt=$3

ci_build_info_file="BitwardenShared/Core/Platform/Utilities/CIBuildInfo.swift"
repository=$(git config --get remote.origin.url)
branch=$(git branch --show-current)
commit_hash=$(git rev-parse --verify HEAD)

echo "🧱 Updating app CI Build info..."
echo "🧱 CI Run ID: ${ci_run_id}"
echo "🧱 CI Run Number: ${ci_run_number}"
echo "🧱 CI Run Attempt: ${ci_run_attempt}"

cat << EOF > ${ci_build_info_file}
enum CIBuildInfo {
    static let info: [String: String] = [
        "Repository": "${repository}",
        "Branch": "${branch}",
        "Commit hash": "${commit_hash}",
        "CI Run ID": "${ci_run_id}",
        "CI Run Number": "${ci_run_number}",
        "CI Run Attempt": "${ci_run_attempt}",
    ]
}
EOF

echo "✅ CI Build info updated successfully."
