#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Absolute path of the script and the fixer root directory
script_path="$(realpath "$0")"
fixer_root_dir="$(dirname "$script_path")"

# Repository details
readonly REPO_OWNER="crasowas"
readonly REPO_NAME="app_privacy_manifest_fixer"

# URL to fetch the latest release information
readonly LATEST_RELEASE_URL="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest"

# Fetch the release information from GitHub API
release_info=$(curl -s "$LATEST_RELEASE_URL")

# Extract the latest release version, download URL, and published time
latest_version=$(echo "$release_info" | grep -o '"tag_name": "[^"]*' | sed 's/"tag_name": "//')
download_url=$(echo "$release_info" | grep -o '"zipball_url": "[^"]*' | sed 's/"zipball_url": "//')
published_time=$(echo "$release_info" | grep -o '"published_at": "[^"]*' | sed 's/"published_at": "//')

# Ensure the latest version, download URL, and published time are successfully retrieved
if [ -z "$latest_version" ] || [ -z "$download_url" ]  || [ -z "$published_time" ]; then
    echo "Unable to fetch the latest release information."
    echo "Request URL: $LATEST_RELEASE_URL"
    echo "Response Data: $release_info"
    exit 1
fi

# Convert UTC time to local time
published_time=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "$published_time" +"%s" | xargs -I{} date -j -r {} +"%Y-%m-%d %H:%M:%S %z")

# Read the current version from the VERSION file
if [ ! -f "$fixer_root_dir/VERSION" ]; then
    echo "VERSION file not found."
    exit 1
fi

local_version="$(cat "$fixer_root_dir/VERSION")"

# Skip upgrade if the current version is already the latest
if [ "$local_version" == "$latest_version" ]; then
    echo "Version $latest_version • $published_time."
    echo "Already up-to-date."
    exit 0
fi

# Create a temporary directory for downloading the release
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

download_file_name="latest-release.tar.gz"

# Download the latest release archive
echo "Downloading version $latest_version..."
curl -L "$download_url" -o "$temp_dir/$download_file_name"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Download failed, please check your network connection and try again."
    exit 1
fi

# Extract the downloaded release archive
echo "Extracting files..."
tar -xzf "$temp_dir/$download_file_name" -C "$temp_dir"

# Locate the extracted release directory
extracted_release_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -name "*$REPO_NAME*" | head -n 1)

# Ensure the extracted release directory was found
if [ -z "$extracted_release_dir" ]; then
    echo "Could not find the extracted release directory for the latest version."
    exit 1
fi

user_templates_dir="$fixer_root_dir/Templates/UserTemplates"
user_templates_backup_dir="$temp_dir/Templates/UserTemplates"

# Backup the user templates directory if it exists
if [ -d "$user_templates_dir" ]; then
    echo "Backing up user templates..."
    mkdir -p "$user_templates_backup_dir"
    rsync -a --exclude='.*' "$user_templates_dir/" "$user_templates_backup_dir/"
fi

# Replace old version files with the new version files
echo "Replacing old version files..."
rsync -a --delete "$extracted_release_dir/" "$fixer_root_dir/"

# Restore the user templates from the backup
if [ -d "$user_templates_backup_dir" ]; then
    echo "Restoring user templates..."
    rsync -a --exclude='.*' "$user_templates_backup_dir/" "$user_templates_dir/"
fi

# Upgrade complete
echo "Version $latest_version • $published_time."
echo "Upgrade completed successfully!"
