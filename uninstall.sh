#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Check if the project path is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <project_path>"
    exit 1
fi

project_path="$1"

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
    gem install xcodeproj || { echo "Failed to install 'xcodeproj'."; exit 1; }
fi

script_path="$(realpath "$0")"
fixer_root_dir="$(dirname "$script_path")"

# Convert project path to an absolute path if it is relative
if [[ ! "$project_path" = /* ]]; then
    project_path="$(realpath "$project_path")"
fi

# Execute the Ruby helper script
ruby "$fixer_root_dir/Helper/xcode_uninstall_helper.rb" "$project_path"
