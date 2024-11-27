#!/bin/bash
# Download Artifacts Script
#
# This script downloads build artifacts from a GitHub Actions run and processes them
# for the GitHub Release upload. It requires:
#   - GitHub CLI (gh) to be installed and authenticated
#   - Two arguments:
#     1. Target path where artifacts should be downloaded
#     2. GitHub Actions run ID to download artifacts from
#
# Example usage:
#   ./download-artifacts.sh 2024.10.2 1234567890
#
# The script will:
# 1. Create the target directory if it doesn't exist
# 2. Download all artifacts from the specified GitHub Actions run
# 3. Process the artifacts by zipping them with the same name as the folder


if [ $# -ne 2 ]; then
    echo "Usage: $0 <path> <github_run_id>"
    exit 1
fi

TARGET_PATH="$1"
GITHUB_RUN_ID="$2"

mkdir -p "$TARGET_PATH"

cd "$TARGET_PATH" || exit 1

echo "Downloading artifacts from GitHub run $GITHUB_RUN_ID..."
gh run download "$GITHUB_RUN_ID"

# Output downloaded files
file_count=$(find . -type f | wc -l)
if [ "$file_count" -eq 0 ]; then
    echo "No files downloaded, processing skipped."
    exit 0
fi

echo "Downloaded $file_count file(s)."
echo "Downloaded files:"
find . -type f

# Process downloaded artifacts
for dir in */; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    # Remove trailing slash from directory name
    dirname=${dir%/}
    basename=$(basename "$dirname")
    zip -r -q "${basename}.zip" "$dirname"
    rm -rf "$dirname"
done


