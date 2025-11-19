#!/bin/bash
# Download Artifacts Script
#
# This script downloads build artifacts from a GitHub Actions run and processes them
# for the GitHub Release upload. It requires:
#   - GitHub CLI (gh) to be installed and authenticated
#   - Arguments:
#     1. Target path where artifacts should be downloaded
#     2. GitHub Actions run ID to download artifacts from
#     3. (Optional) Filter type: "download_all", "release_bwpm", or "release_bwa"
#
# Example usage:
#   ./download-artifacts.sh 2024.10.2 1234567890
#   ./download-artifacts.sh 2024.10.2 1234567890 download_all
#   ./download-artifacts.sh 2024.10.2 1234567890 release_bwpm
#
# The script will:
# 1. Create the target directory if it doesn't exist
# 2. Download all artifacts from the specified GitHub Actions run (or filtered subset)
# 3. Process the artifacts by zipping them with the same name as the folder

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo "Usage: $0 <path> <github_run_id> [filter_type]"
    echo "  filter_type: 'download_all' (default), 'release_bwpm', or 'release_bwa'"
    exit 1
fi

TARGET_PATH="$1"
GITHUB_RUN_ID="$2"
FILTER_TYPE="${3:-download_all}"

mkdir -p "$TARGET_PATH"

cd "$TARGET_PATH" || exit 1

echo "🏃‍♂️💨 Downloading artifacts from GitHub run $GITHUB_RUN_ID..."

if [[ "$FILTER_TYPE" == "download_all" ]]; then
    gh run download "$GITHUB_RUN_ID"
else
    echo "🔍 Filtering artifacts for $FILTER_TYPE..."

    all_artifacts=$(gh api repos/bitwarden/ios/actions/runs/"$GITHUB_RUN_ID"/artifacts --jq '.artifacts[].name')
    echo "🔍 Artifacts from run $GITHUB_RUN_ID:"
    echo "$all_artifacts"
    echo

    if [[ "$FILTER_TYPE" == "release_bwpm" ]]; then
        filter_pattern="com.8bit.bitwarden-.*.ipa"
    elif [[ "$FILTER_TYPE" == "release_bwa" ]]; then
        filter_pattern="com.bitwarden.authenticator-.*.ipa"
    else
        echo "❌ Unknown filter type: $FILTER_TYPE"
        exit 1
    fi

    filtered_artifacts=$(echo "$all_artifacts" | grep -E "$filter_pattern")

    if [ -z "$filtered_artifacts" ]; then
        echo "👀 No matching artifacts found for $FILTER_TYPE, processing skipped."
        exit 0
    fi

    echo "📋 Artifacts to download:"
    echo "$filtered_artifacts"

    download_cmd="gh run download $GITHUB_RUN_ID -n version-info"
    while IFS= read -r artifact; do
        download_cmd="$download_cmd -n \"$artifact\""
    done <<< "$filtered_artifacts"

    echo "Executing: $download_cmd"
    eval "$download_cmd"
    echo "Finished downloading artifacts."
fi

# Output downloaded files
file_count=$(find . -type f | wc -l)
if [ "$file_count" -eq 0 ]; then
    echo "👀 No files downloaded, processing skipped."
    exit 0
fi

echo "🎉 Downloaded $file_count file(s)."
echo "Downloaded files:"
find . -type f

# Process downloaded artifacts
echo "📦 Zipping artifacts"
for dir in */; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    # Remove trailing slash from directory name
    dirname=${dir%/}
    basename=$(basename "$dirname")
    zip -r -q "${basename}.zip" "$dirname"
    echo "    🍣 Created $basename.zip"
    rm -rf "$dirname"
done
echo "🍱 Finished zipping!"
