#!/bin/bash

set -e

PROJECT_FILES=("project-bwk.yml" "project-bwa.yml" "project-pm.yml")

echo "Checking for dependency updates..."

function get_latest_release() {
    local repo_url="$1"
    local repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')
    
    # First try to get the latest stable release (non-prerelease)
    local latest_tag=$(gh api "repos/$repo_path/releases" | jq -r '.[] | select(.prerelease == false or .prerelease == null) | .tag_name' | grep -viE '(beta|alpha|rc|pre|dev|snapshot)' | head -1)
    
    # If no stable releases found, fall back to tags but filter out beta/alpha/rc versions
    if [[ -z "$latest_tag" ]]; then
        local latest_tag=$(gh api "repos/$repo_path/tags" | jq -r '.[] | select(.prerelease == false or .prerelease == null) | .tag_name' | grep -viE '(beta|alpha|rc|pre|dev|snapshot)' | head -1)
    fi
    
    echo "$latest_tag"
}

function get_latest_commit() {
    local repo_url="$1"
    local branch="$2"
    local repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')
    
    local latest_commit=$(gh api "repos/$repo_path/commits/$branch" | jq -r '.sha')
    
    echo "$latest_commit"
}

function version_compare() {
    local current="$1"
    local latest="$2"
    
    current_clean=$(echo "$current" | sed 's/^v//')
    latest_clean=$(echo "$latest" | sed 's/^v//')
    
    if [[ "$current_clean" == "$latest_clean" ]]; then
        return 1
    fi
    
    printf '%s\n%s\n' "$current_clean" "$latest_clean" | sort -V | head -1 | grep -q "^$current_clean$"
}

function process_project_file() {
    local PROJECT_FILE="$1"
    local TEMP_FILE=$(mktemp)
    
    if [[ ! -f "$PROJECT_FILE" ]]; then
        echo "Warning: $PROJECT_FILE not found, skipping..."
        return
    fi
    
    echo "Processing $PROJECT_FILE..."
    
    cp "$PROJECT_FILE" "$TEMP_FILE"
    
    # Extract all package names using yq
    package_names=$(yq eval '.packages | keys | .[]' "$PROJECT_FILE" 2>/dev/null || echo "")
    
    if [[ -z "$package_names" ]]; then
        echo "  No packages found in $PROJECT_FILE"
        return
    fi
    
    for package_name in $package_names; do
        echo "  Processing package: $package_name"
        
        # Extract package info using yq
        url=$(yq eval ".packages.$package_name.url" "$PROJECT_FILE" 2>/dev/null)
        version=$(yq eval ".packages.$package_name.exactVersion" "$PROJECT_FILE" 2>/dev/null)
        revision=$(yq eval ".packages.$package_name.revision" "$PROJECT_FILE" 2>/dev/null)
        branch=$(yq eval ".packages.$package_name.branch" "$PROJECT_FILE" 2>/dev/null)
        
        # Clean up null values from yq
        [[ "$url" == "null" ]] && url=""
        [[ "$version" == "null" ]] && version=""
        [[ "$revision" == "null" ]] && revision=""
        [[ "$branch" == "null" ]] && branch=""
        
        # Only process GitHub URLs
        if [[ -n "$url" ]] && [[ "$url" =~ ^https://github\.com/ ]]; then
            if [[ -n "$version" ]]; then
                latest_version=$(get_latest_release "$url")
                
                if [[ -n "$latest_version" ]] && version_compare "$version" "$latest_version"; then
                    echo "    Updating $package_name from $version to $latest_version"
                    yq eval ".packages.$package_name.exactVersion = \"$latest_version\"" -i "$TEMP_FILE"
                else
                    echo "    $package_name is up to date ($version)"
                fi
                
            elif [[ -n "$revision" ]] && [[ -n "$branch" ]]; then
                latest_commit=$(get_latest_commit "$url" "$branch")
                
                if [[ -n "$latest_commit" ]] && [[ "$revision" != "$latest_commit" ]]; then
                    echo "    Updating $package_name revision from $revision to $latest_commit"
                    yq eval ".packages.$package_name.revision = \"$latest_commit\"" -i "$TEMP_FILE"
                else
                    echo "    $package_name revision is up to date ($revision)"
                fi
            else
                echo "    $package_name: No version or revision info found, skipping..."
            fi
        else
            echo "    $package_name: Not a GitHub URL or no URL found, skipping..."
        fi
        
        # Clear variables for next iteration
        unset url version revision branch
    done
    
    if ! diff -q "$PROJECT_FILE" "$TEMP_FILE" > /dev/null; then
        echo "  Updates found. Applying changes to $PROJECT_FILE..."
        mv "$TEMP_FILE" "$PROJECT_FILE"
        echo "  File updated successfully!"
    else
        echo "  No updates needed for $PROJECT_FILE."
        rm "$TEMP_FILE"
    fi
    
    if [[ -f "${PROJECT_FILE}.bak" ]]; then
        rm "${PROJECT_FILE}.bak"
    fi
}

for project_file in "${PROJECT_FILES[@]}"; do
    process_project_file "$project_file"
done

echo "All project files processed!"