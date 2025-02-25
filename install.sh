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

options=()
install_builds_only=false

# Check if the `--install-builds-only` option is provided and separate it from other options
for arg in "$@"; do
  if [ "$arg" == "--install-builds-only" ]; then
    install_builds_only=true
  else
    options+=("$arg")
  fi
done

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
fixer_portable_path="$fixer_root_dir"

# Convert project path to an absolute path if it is relative
if [[ ! "$project_path" = /* ]]; then
    project_path="$(realpath "$project_path")"
fi

# If the fixer root directory is inside the project path, make the path portable
if [[ "$fixer_root_dir" == "$project_path"* ]]; then
    # Extract the path of fixer root directory relative to the project path
    fixer_relative_path="${fixer_root_dir#$project_path}"
    # Formulate a portable path using the `PROJECT_DIR` environment variable provided by Xcode
    fixer_portable_path="\${PROJECT_DIR}${fixer_relative_path}"
fi

run_script_content="\"$fixer_portable_path/fixer.sh\" ${options[@]}"

# Execute the Ruby helper script
ruby "$fixer_root_dir/Helper/xcode_install_helper.rb" "$project_path" "$run_script_content" "$install_builds_only"
