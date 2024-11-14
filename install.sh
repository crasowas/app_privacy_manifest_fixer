#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Check if at least one argument (project_path) is provided
if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 <project_path> [options...]"
    exit 1
fi

project_path="$1"

shift

# Capture any additional options after <project_path>, to be passed to `fixer.sh`
options="$*"

# Verify Ruby installation
if ! command -v ruby &>/dev/null; then
    echo "Ruby is not installed. Please install Ruby and try again."
    exit 1
fi

# Check if xcodeproj gem is installed
if ! gem list -i xcodeproj &>/dev/null; then
    echo "The 'xcodeproj' gem is not installed."
    read -p "Would you like to install it now? [Y/n] " response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        echo "Please install 'xcodeproj' manually and re-run the script."
        exit 1
    fi
    gem install xcodeproj || { echo "Failed to install xcodeproj"; exit 1; }
fi

script_path="$(realpath "$0")"
fixer_path="$(dirname "$script_path")"
run_script_content="$fixer_path"

# If the fixer path is within the project path, use a relative path for portability
if [[ "$fixer_path" == "$project_path"* ]]; then
    # Strip the project path prefix to make the fixer path relative
    relative_path="${fixer_path#$project_path}"
    # Append ${PROJECT_DIR} to form a project-relative path for the fixer
    run_script_content="\${PROJECT_DIR}${relative_path}"
fi

run_script_content="$run_script_content/fixer.sh $options"

# Execute the Ruby helper script
ruby "$fixer_path/Helper/xcode_helper.rb" "$project_path" "$run_script_content"
