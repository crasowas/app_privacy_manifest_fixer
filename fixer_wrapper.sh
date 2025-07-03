#!/bin/bash

# Copyright (c) 2025, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

set -e

# Absolute path of the script and the tool's root directory
script_path="$(realpath "$0")"
tool_root_path="$(dirname "$script_path")"

# Load common constants and utils
source "$tool_root_path/Common/constants.sh"
source "$tool_root_path/Common/utils.sh"

input_path="$1"
if [ -z "$input_path" ]; then
    echo "Usage: $0 <path> [options]"
    exit 1
fi

shift

# Remaining options passed to fixer script
options=("$@")

# Input types
readonly INPUT_TYPE_APP="app"
readonly INPUT_TYPE_IPA="ipa"
readonly INPUT_TYPE_XCARCHIVE="xcarchive"

input_type=""

# Determine input type
if [ -f "$input_path" ] && [[ "$input_path" == *.ipa ]]; then
  input_type="$INPUT_TYPE_IPA"
elif [ -d "$input_path" ] && [[ "$input_path" == *.app ]]; then
  input_type="$INPUT_TYPE_APP"
elif [ -d "$input_path" ] && [[ "$input_path" == *.xcarchive ]]; then
  input_type="$INPUT_TYPE_XCARCHIVE"
fi

# Validate input type
if [ -z "$input_type" ]; then
    echo "Invalid path: $input_path"
    echo "Supported formats: .app, .ipa, .xcarchive"
    exit 1
fi

# Create a temporary directory for processing
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

app_path=""
input_basename="$(basename "$input_path")"

# Extract or copy app bundle based on type
case "$input_type" in
    "$INPUT_TYPE_APP")
        cp -r "$input_path" "$temp_dir"
        app_path="$temp_dir/$input_basename"
        ;;
    "$INPUT_TYPE_IPA")
        unzip -q "$input_path" -d "$temp_dir"
        app_path=$(find "$temp_dir/Payload" -type d -name "*.app" | head -n 1)
        ;;
    "$INPUT_TYPE_XCARCHIVE")
        cp -r "$input_path" "$temp_dir"
        app_path="$(find "$temp_dir/$input_basename/Products/Applications" -type d -name "*.app" | head -n 1)"
        ;;
esac

# Check if the app exists
if [ ! -d "$app_path" ] || [[ "$app_path" != *.app ]]; then
    echo "Unable to find the app: $app_path"
    exit 1
fi

export WRAPPER_APP_PATH="$app_path"

plist_file="$(get_plist_file "$app_path" "")"
app_version="$(get_plist_version "$plist_file")"
app_short_version="$(get_plist_short_version "$plist_file")"

export WRAPPER_BUILD_DIR="$tool_root_path/Build/${input_basename}_${app_short_version}_${app_version}_$(date +%Y%m%d%H%M%S)"

# Detect and match original code signing identity
if codesign -d "$app_path" &>/dev/null; then
    original_cert_name=$(codesign -dvvv "$app_path" 2>&1 | grep "Authority=" | head -1 | cut -d= -f2-)
    echo "Original code sign identity: $original_cert_name"
    
    available_certs=$(security find-identity -v -p codesigning)
    matched_cert=$(echo "$available_certs" | grep "$original_cert_name" | head -1)

    if [ -n "$matched_cert" ]; then
        matched_cert_id=$(echo "$matched_cert" | awk '{print $2}')
        matched_cert_name=$(echo "$matched_cert" | sed -E 's/.*"(.+)"$/\1/')
        echo "Matched signing identity will be used for automatic re-signing:"
        echo "   → $matched_cert_name | $matched_cert_id"
        
        export EXPANDED_CODE_SIGN_IDENTITY_NAME="$matched_cert_name"
        export EXPANDED_CODE_SIGN_IDENTITY="$matched_cert_id"
    else
        echo "No matching code sign identity found locally, skipping re-signing."
    fi
else
    echo "App is not signed, skipping re-signing."
fi

# Run fixer script
echo ""
echo "Running fixer.sh..."
echo ""
"$tool_root_path/fixer.sh" "${options[@]}"
echo ""

# Backup original input if backup doesn't exist
backup_path="$input_path.bak"
if [ ! -e "$backup_path" ]; then
    if [ -d "$input_path" ]; then
        cp -r "$input_path" "$backup_path"
    elif [ -f "$input_path" ]; then
        cp "$input_path" "$backup_path"
    fi
    echo "Backup created: $backup_path"
else
    echo "Backup already exists, skipping: $backup_path"
fi

# Replace original with modified input
rm -rf "$input_path"
case "$input_type" in
    "$INPUT_TYPE_APP")
        cp -r "$app_path" "$input_path"
        ;;
    "$INPUT_TYPE_IPA")
        (cd "$temp_dir" && zip -qr "$input_path" Payload)
        ;;
    "$INPUT_TYPE_XCARCHIVE")
        cp -r "$temp_dir/$input_basename" "$input_path"
        ;;
esac

echo "Fix completed. Changes have been applied to: $input_path"
