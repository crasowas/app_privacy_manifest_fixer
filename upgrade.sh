#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Absolute path of the script and the fixer directory
script_path="$(realpath "$0")"
fixer_dir="$(dirname "$script_path")"

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
published_time=$(date -d "$published_time" "+%Y-%m-%d %H:%M:%S %z")

# Read the current version from the VERSION file
if [ ! -f "$fixer_dir/VERSION" ]; then
    echo "VERSION file not found."
    exit 1
fi

local_version="$(cat "$fixer_dir/VERSION")"

# Skip upgrade if the current version is already the latest
if [ "$local_version" == "$latest_version" ]; then
    echo "Version $latest_version • $published_time."
    echo "Already up-to-date."
    exit 0
fi

# Create a temporary directory for downloading the release
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

# Download the latest release package
echo "Downloading version $latest_version..."
curl -L "$download_url" -o "$temp_dir/latest-release.tar.gz"

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Download failed, check your network connection."
    exit 1
fi

# Extract the downloaded release package
echo "Extracting files..."
tar -xzf "$temp_dir/latest-release.tar.gz" -C "$temp_dir"

# Locate the extracted directory for the release
extracted_dir=$(find "$temp_dir" -mindepth 1 -maxdepth 1 -type d -name "*$REPO_NAME*" | head -n 1)

# Ensure the extracted directory was found
if [ -z "$extracted_dir" ]; then
    echo "Could not find the extracted directory for the latest version."
    exit 1
fi

user_templates_dir="$fixer_dir/Templates/UserTemplates"
user_templates_backup_dir="$temp_dir/Templates/UserTemplates"

# Backup the UserTemplates directory if it exists
if [ -d "$user_templates_dir" ]; then
    echo "Backing up files..."
    mkdir -p "$user_templates_backup_dir"
    cp -r "$user_templates_dir/"* "$user_templates_backup_dir"
fi

# Replace current version files
echo "Replacing files..."
rsync -av --delete "$extracted_dir/" "$fixer_dir/"

# Restore the backup of the UserTemplates directory
if [ -d "$user_templates_backup_dir" ]; then
    echo "Restoring files..."
    mkdir -p "$user_templates_dir"
    cp -r "$user_templates_backup_dir/"* "$user_templates_dir"
fi

# Upgrade complete
echo "Version $latest_version • $published_time."
echo "Upgrade completed successfully!"
