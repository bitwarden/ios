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


# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <path> <github_run_id>"
    exit 1
fi

# Store arguments
TARGET_PATH="$1"
GITHUB_RUN_ID="$2"

# Create target directory if it doesn't exist
mkdir -p "$TARGET_PATH"

# Change to target directory
cd "$TARGET_PATH" || exit 1

# Download artifacts using GitHub CLI
echo "Downloading artifacts from GitHub run $GITHUB_RUN_ID..."
#gh run download "$GITHUB_RUN_ID"

# Process downloaded artifacts
for dir in */; do
if [ -d "$dir" ]; then
    # Remove trailing slash from directory name
    dirname=${dir%/}
    # Get just the folder name without the path
    basename=$(basename "$dirname")
    echo $dirname $basename
    # Create zip file with same name as directory
    zip -r "${basename}.zip" "$dirname"
    # Remove the original directory
    rm -rf "$dirname"
fi
done


