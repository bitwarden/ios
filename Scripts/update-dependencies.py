#!/usr/bin/env python3

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional

import yaml
from packaging import version


PROJECT_FILES = ["project-bwk.yml", "project-bwa.yml", "project-pm.yml"]


def run_gh_api(endpoint: str) -> Dict:
    """Run gh api command and return JSON response."""
    try:
        result = subprocess.run(
            ["gh", "api", endpoint],
            capture_output=True,
            text=True,
            check=True
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error calling GitHub API: {e}")
        return {}
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON response: {e}")
        return {}


def get_latest_release(repo_url: str) -> Optional[str]:
    """Get the latest stable release tag for a GitHub repository."""
    repo_path = repo_url.replace("https://github.com/", "")
    
    # First try to get the latest stable release (non-prerelease)
    releases = run_gh_api(f"repos/{repo_path}/releases")
    if releases:
        for release in releases:
            if not release.get("prerelease", False):
                tag_name = release.get("tag_name", "")
                if not re.search(r'(beta|alpha|rc|pre|dev|snapshot)', tag_name, re.IGNORECASE):
                    return tag_name
    
    # If no stable releases found, fall back to tags but filter out beta/alpha/rc versions
    tags = run_gh_api(f"repos/{repo_path}/tags")
    if tags:
        for tag in tags:
            tag_name = tag.get("name", "")
            if not re.search(r'(beta|alpha|rc|pre|dev|snapshot)', tag_name, re.IGNORECASE):
                return tag_name
    
    return None


def get_latest_commit(repo_url: str, branch: str) -> Optional[str]:
    """Get the latest commit SHA for a specific branch."""
    repo_path = repo_url.replace("https://github.com/", "")
    
    commit_data = run_gh_api(f"repos/{repo_path}/commits/{branch}")
    return commit_data.get("sha")


def version_compare(current: str, latest: str) -> bool:
    """Compare versions and return True if current is older than latest."""
    current_clean = current.lstrip("v")
    latest_clean = latest.lstrip("v")
    
    if current_clean == latest_clean:
        return False
    
    try:
        return version.parse(current_clean) < version.parse(latest_clean)
    except version.InvalidVersion:
        # Fallback to string comparison if version parsing fails
        return current_clean != latest_clean


def process_project_file(project_file: str) -> None:
    """Process a single project file to update dependencies."""
    if not os.path.isfile(project_file):
        print(f"Warning: {project_file} not found, skipping...")
        return
    
    print(f"Processing {project_file}...")
    
    # Read the YAML file
    try:
        with open(project_file, 'r') as f:
            data = yaml.safe_load(f)
    except yaml.YAMLError as e:
        print(f"Error reading {project_file}: {e}")
        return
    
    packages = data.get("packages", {})
    if not packages:
        print(f"  No packages found in {project_file}")
        return
    
    updated = False
    
    for package_name, package_info in packages.items():
        print(f"  Processing package: {package_name}")
        
        url = package_info.get("url", "")
        exact_version = package_info.get("exactVersion")
        revision = package_info.get("revision")
        branch = package_info.get("branch")
        
        # Only process GitHub URLs
        if url and url.startswith("https://github.com/"):
            if exact_version:
                latest_version = get_latest_release(url)
                
                if latest_version and version_compare(exact_version, latest_version):
                    print(f"    Updating {package_name} from {exact_version} to {latest_version}")
                    package_info["exactVersion"] = latest_version
                    updated = True
                else:
                    print(f"    {package_name} is up to date ({exact_version})")
            
            elif revision and branch:
                latest_commit = get_latest_commit(url, branch)
                
                if latest_commit and revision != latest_commit:
                    print(f"    Updating {package_name} revision from {revision} to {latest_commit}")
                    package_info["revision"] = latest_commit
                    updated = True
                else:
                    print(f"    {package_name} revision is up to date ({revision})")
            else:
                print(f"    {package_name}: No version or revision info found, skipping...")
        else:
            print(f"    {package_name}: Not a GitHub URL or no URL found, skipping...")
    
    # Write back to file if updated
    if updated:
        print(f"  Updates found. Applying changes to {project_file}...")
        try:
            with open(project_file, 'w') as f:
                yaml.safe_dump(data, f, default_flow_style=False, sort_keys=False)
            print("  File updated successfully!")
        except Exception as e:
            print(f"  Error writing {project_file}: {e}")
    else:
        print(f"  No updates needed for {project_file}.")


def main():
    """Main function to process all project files."""
    print("Checking for dependency updates...")
    
    for project_file in PROJECT_FILES:
        process_project_file(project_file)
    
    print("All project files processed!")


if __name__ == "__main__":
    main()