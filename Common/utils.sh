#!/bin/bash

# Copyright (c) 2025, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

set -e

# Prevent duplicate loading
if [ -n "$UTILS_SH_LOADED" ]; then
    return
fi

readonly UTILS_SH_LOADED=1

# Absolute path of the script and the tool's root directory
script_path="$(realpath "${BASH_SOURCE[0]}")"
tool_root_path="$(dirname "$(dirname "$script_path")")"

# Load common constants
source "$tool_root_path/Common/constants.sh"

# Print the elements of an array along with their indices
function print_array() {
    local -a array=("$@")
    
    for ((i=0; i<${#array[@]}; i++)); do
        echo "[$i] $(decode_path "${array[i]}")"
    done
}

# Split a string into substrings using a specified delimiter
function split_string_by_delimiter() {
    local string="$1"
    local -a substrings=()

    IFS="$DELIMITER" read -ra substrings <<< "$string"

    echo "${substrings[@]}"
}

# Encode a path string by replacing space with an escape character
function encode_path() {
    echo "$1" | sed "s/ /$SPACE_ESCAPE/g"
}

# Decode a path string by replacing encoded character with space
function decode_path() {
    echo "$1" | sed "s/$SPACE_ESCAPE/ /g"
}

# Get the dependency name by removing common suffixes
function get_dependency_name() {
    local path="$1"
    
    local dir_name="$(basename "$path")"
    # Remove `.app`, `.framework`, and `.xcframework` suffixes
    local dep_name="${dir_name%.*}"
    
    echo "$dep_name"
}

# Get the executable name from the specified `Info.plist` file
function get_plist_executable() {
    local plist_file="$1"
    
    if [ ! -f "$plist_file" ]; then
        echo ""
    else
        /usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$plist_file" 2>/dev/null || echo ""
    fi
}

# Get the version from the specified `Info.plist` file
function get_plist_version() {
    local plist_file="$1"

    if [ ! -f "$plist_file" ]; then
        echo "$UNKNOWN_VERSION"
    else
        /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist_file" 2>/dev/null || echo "$UNKNOWN_VERSION"
    fi
}

# Get the path of the specified framework version
function get_framework_path() {
    local path="$1"
    local version_path="$2"

    if [ -z "$version_path" ]; then
        echo "$path"
    else
        echo "$path/$version_path"
    fi
}

# Search for privacy manifest files in the specified directory
function search_privacy_manifest_files() {
    local path="$1"
    local -a privacy_manifest_files=()

    # Create a temporary file to store search results
    local temp_file="$(mktemp)"

    # Ensure the temporary file is deleted on script exit
    trap "rm -f $temp_file" EXIT

    # Find privacy manifest files within the specified directory and store the results in the temporary file
    find "$path" -type f -name "$PRIVACY_MANIFEST_FILE_NAME" -print0 2>/dev/null > "$temp_file"

    while IFS= read -r -d '' file; do
        privacy_manifest_files+=($(encode_path "$file"))
    done < "$temp_file"

    echo "${privacy_manifest_files[@]}"
}

# Get the privacy manifest file with the shortest path
function get_privacy_manifest_file() {
    local privacy_manifest_file="$(printf "%s\n" "$@" | awk '{print length, $0}' | sort -n | head -n1 | cut -d ' ' -f2-)"
    
    echo "$(decode_path "$privacy_manifest_file")"
}
