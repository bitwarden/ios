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
    
    # Extract all package names from the packages section
    package_names=$(sed -n '/^packages:/,/^[^[:space:]]/p' "$PROJECT_FILE" | grep '^  [^[:space:]].*:$' | sed 's/^  //' | sed 's/:$//' | sort -u)
    
    for package_name in $package_names; do
        # Clean up package name (remove colon if present)
        package_name=$(echo "$package_name" | sed 's/:$//')
        
        # Skip empty lines
        [[ -z "$package_name" ]] && continue
        
        echo "  Processing package: $package_name"
        
        # Extract package info using more robust awk
        package_info=$(awk -v pkg="$package_name" '
        /^packages:/{in_packages=1; next}
        in_packages && /^[[:space:]]*[^[:space:]]*:/ && $1 !~ /^[[:space:]]*'$package_name':$/{if($1 ~ /^[[:space:]]*[^[:space:]]*:$/) current_pkg=""; next}
        in_packages && /^[[:space:]]*'$package_name':$/{current_pkg=pkg; next}
        in_packages && current_pkg==pkg && /url:/{url=$2; next}
        in_packages && current_pkg==pkg && /exactVersion:/{version=$2; next}
        in_packages && current_pkg==pkg && /revision:/{revision=$2; next}
        in_packages && current_pkg==pkg && /branch:/{branch=$2; next}
        in_packages && /^[^[:space:]]/{in_packages=0}
        END{
            if(url) print "url=" url
            if(version) print "version=" version
            if(revision) print "revision=" revision
            if(branch) print "branch=" branch
        }' "$PROJECT_FILE")
        
        if [[ -z "$package_info" ]]; then
            echo "    No package info found for $package_name, skipping..."
            continue
        fi
        
        # Parse the package info
        eval "$package_info"
        
        # Only process GitHub URLs
        if [[ -n "$url" ]] && [[ "$url" =~ ^https://github\.com/ ]]; then
            if [[ -n "$version" ]]; then
                latest_version=$(get_latest_release "$url")
                
                if [[ -n "$latest_version" ]] && version_compare "$version" "$latest_version"; then
                    echo "    Updating $package_name from $version to $latest_version"
                    # Use more specific sed pattern to target this package's version
                    awk -v pkg="$package_name" -v old_ver="$version" -v new_ver="$latest_version" '
                    /^packages:/{in_packages=1}
                    in_packages && /^[[:space:]]*'$package_name':$/{current_pkg=1; print; next}
                    in_packages && current_pkg && /exactVersion:/{
                        gsub(old_ver, new_ver); current_pkg=0
                    }
                    in_packages && /^[[:space:]]*[^[:space:]]*:$/ && !/^[[:space:]]*'$package_name':$/{current_pkg=0}
                    in_packages && /^[^[:space:]]/{in_packages=0; current_pkg=0}
                    {print}' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
                else
                    echo "    $package_name is up to date ($version)"
                fi
                
            elif [[ -n "$revision" ]] && [[ -n "$branch" ]]; then
                latest_commit=$(get_latest_commit "$url" "$branch")
                
                if [[ -n "$latest_commit" ]] && [[ "$revision" != "$latest_commit" ]]; then
                    echo "    Updating $package_name revision from $revision to $latest_commit"
                    # Use more specific sed pattern to target this package's revision
                    awk -v pkg="$package_name" -v old_rev="$revision" -v new_rev="$latest_commit" '
                    /^packages:/{in_packages=1}
                    in_packages && /^[[:space:]]*'$package_name':$/{current_pkg=1; print; next}
                    in_packages && current_pkg && /revision:/{
                        gsub(old_rev, new_rev); current_pkg=0
                    }
                    in_packages && /^[[:space:]]*[^[:space:]]*:$/ && !/^[[:space:]]*'$package_name':$/{current_pkg=0}
                    in_packages && /^[^[:space:]]/{in_packages=0; current_pkg=0}
                    {print}' "$TEMP_FILE" > "$TEMP_FILE.tmp" && mv "$TEMP_FILE.tmp" "$TEMP_FILE"
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