#!/bin/bash

set -euo pipefail

mint bootstrap

# Handle script being called from repo root or Scripts folder
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
repo_root=$(dirname "$script_dir")

mint run xcodegen --spec "$repo_root/project-bwa.yml"
