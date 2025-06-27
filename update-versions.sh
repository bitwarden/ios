#!/bin/bash

set -e

PROJECT_FILES=("project-bwk.yml" "project-bwa.yml" "project-pm.yml")

echo "Checking for dependency updates..."

function get_latest_release() {
    local repo_url="$1"
    local repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')
    
    local latest_tag=$(curl -s "https://api.github.com/repos/$repo_path/releases/latest" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]*)",/\1/')
    
    if [[ -z "$latest_tag" ]]; then
        local latest_tag=$(curl -s "https://api.github.com/repos/$repo_path/tags" | grep '"name":' | head -1 | sed -E 's/.*"name": "([^"]*)",/\1/')
    fi
    
    echo "$latest_tag"
}

function get_latest_commit() {
    local repo_url="$1"
    local branch="$2"
    local repo_path=$(echo "$repo_url" | sed 's|https://github.com/||')
    
    local latest_commit=$(curl -s "https://api.github.com/repos/$repo_path/commits/$branch" | grep '"sha":' | head -1 | sed -E 's/.*"sha": "([^"]*)",/\1/')
    
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
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*([^:]+):[[:space:]]*$ ]]; then
            package_name=$(echo "$line" | sed -E 's/^[[:space:]]*([^:]+):[[:space:]]*$/\1/')
            
            if [[ "$package_name" =~ ^(BitwardenSdk|Firebase|SwiftUIIntrospect|SnapshotTesting|ViewInspector)$ ]]; then
                echo "  Processing package: $package_name"
                
                url_line=$(awk -v start="$package_name:" '/^[[:space:]]*'$package_name':/{flag=1; next} flag && /^[[:space:]]*[^[:space:]]/ && !/^[[:space:]]*url:/ && !/^[[:space:]]*exactVersion:/ && !/^[[:space:]]*revision:/ && !/^[[:space:]]*branch:/{flag=0} flag && /url:/{print; exit}' "$PROJECT_FILE")
                version_line=$(awk -v start="$package_name:" '/^[[:space:]]*'$package_name':/{flag=1; next} flag && /^[[:space:]]*[^[:space:]]/ && !/^[[:space:]]*url:/ && !/^[[:space:]]*exactVersion:/ && !/^[[:space:]]*revision:/ && !/^[[:space:]]*branch:/{flag=0} flag && /exactVersion:/{print; exit}' "$PROJECT_FILE")
                revision_line=$(awk -v start="$package_name:" '/^[[:space:]]*'$package_name':/{flag=1; next} flag && /^[[:space:]]*[^[:space:]]/ && !/^[[:space:]]*url:/ && !/^[[:space:]]*exactVersion:/ && !/^[[:space:]]*revision:/ && !/^[[:space:]]*branch:/{flag=0} flag && /revision:/{print; exit}' "$PROJECT_FILE")
                branch_line=$(awk -v start="$package_name:" '/^[[:space:]]*'$package_name':/{flag=1; next} flag && /^[[:space:]]*[^[:space:]]/ && !/^[[:space:]]*url:/ && !/^[[:space:]]*exactVersion:/ && !/^[[:space:]]*revision:/ && !/^[[:space:]]*branch:/{flag=0} flag && /branch:/{print; exit}' "$PROJECT_FILE")
                
                if [[ -n "$url_line" ]]; then
                    repo_url=$(echo "$url_line" | sed -E 's/.*url:[[:space:]]*(.*)/\1/')
                    
                    if [[ -n "$version_line" ]]; then
                        current_version=$(echo "$version_line" | sed -E 's/.*exactVersion:[[:space:]]*(.*)/\1/')
                        latest_version=$(get_latest_release "$repo_url")
                        
                        if [[ -n "$latest_version" ]] && version_compare "$current_version" "$latest_version"; then
                            echo "    Updating $package_name from $current_version to $latest_version"
                            sed -i.bak -E "s|(.*exactVersion:[[:space:]]*)[^[:space:]]*(.*)|\1$latest_version\2|" "$TEMP_FILE"
                        else
                            echo "    $package_name is up to date ($current_version)"
                        fi
                        
                    elif [[ -n "$revision_line" ]] && [[ -n "$branch_line" ]]; then
                        current_revision=$(echo "$revision_line" | sed -E 's/.*revision:[[:space:]]*(.*)/\1/')
                        branch=$(echo "$branch_line" | sed -E 's/.*branch:[[:space:]]*(.*)/\1/')
                        latest_commit=$(get_latest_commit "$repo_url" "$branch")
                        
                        if [[ -n "$latest_commit" ]] && [[ "$current_revision" != "$latest_commit" ]]; then
                            echo "    Updating $package_name revision from $current_revision to $latest_commit"
                            sed -i.bak -E "s|(.*revision:[[:space:]]*)[^[:space:]]*(.*)|\1$latest_commit\2|" "$TEMP_FILE"
                        else
                            echo "    $package_name revision is up to date ($current_revision)"
                        fi
                    fi
                fi
            fi
        fi
    done < "$PROJECT_FILE"
    
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