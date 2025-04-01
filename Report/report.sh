#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

set -e

# Absolute path of the script and the tool's root directory
script_path="$(realpath "$0")"
tool_root_path="$(dirname "$(dirname "$script_path")")"

# Load common constants and utils
source "$tool_root_path/Common/constants.sh"
source "$tool_root_path/Common/utils.sh"

# Path to the app
app_path="$1"

# Check if the app exists
if [ ! -d "$app_path" ] || [[ "$app_path" != *.app ]]; then
    echo "Unable to find the app: $app_path"
    exit 1
fi

# Check if the app is iOS or macOS
is_ios_app=true
frameworks_dir="$app_path/Frameworks"
if [ -d "$app_path/Contents/MacOS" ]; then
    is_ios_app=false
    frameworks_dir="$app_path/Contents/Frameworks"
fi

report_output_file="$2"
# Additional arguments as template usage records
template_usage_records=("${@:2}")

# Copy report template to output file
report_template_file="$tool_root_path/Report/report-template.html"
if ! rsync -a "$report_template_file" "$report_output_file"; then
    echo "Failed to copy the report template to $report_output_file"
    exit 1
fi

# Read the current tool's version from the VERSION file
tool_version_file="$tool_root_path/VERSION"
tool_version="N/A"
if [ -f "$tool_version_file" ]; then
    tool_version="$(cat "$tool_version_file")"
fi

# Initialize report content
report_content=""

# Get the template file used for fixing based on the app or framework name
function get_used_template_file() {
    local name="$1"
    
    for template_usage_record in "${template_usage_records[@]}"; do
        if [[ "$template_usage_record" == "$name$DELIMITER"* ]]; then
            echo "${template_usage_record#*$DELIMITER}"
            return
        fi
    done
    
    echo ""
}

# Analyze accessed API types and their corresponding reasons
function analyze_privacy_accessed_api() {
    local privacy_manifest_file="$1"
    local -a results=()

    if [ -f "$privacy_manifest_file" ]; then
        local api_count=$(xmllint --xpath 'count(//dict/key[text()="NSPrivacyAccessedAPIType"])' "$privacy_manifest_file")

        for ((i=1; i<=api_count; i++)); do
            local api_type=$(xmllint --xpath "(//dict/key[text()='NSPrivacyAccessedAPIType']/following-sibling::string[1])[$i]/text()" "$privacy_manifest_file" 2>/dev/null)
            local api_reasons=$(xmllint --xpath "(//dict/key[text()='NSPrivacyAccessedAPITypeReasons']/following-sibling::array[1])[position()=$i]/string/text()" "$privacy_manifest_file" 2>/dev/null | paste -sd "/" -)
            
            if [ -z "$api_type" ]; then
                api_type="N/A"
            fi
            
            if [ -z "$api_reasons" ]; then
                api_reasons="N/A"
            fi
            
            results+=("$api_type$DELIMITER$api_reasons")
        done
    fi

    echo "${results[@]}"
}

# Get the path to the `Info.plist` file for the specified app or framework
function get_plist_file() {
    local path="$1"
    local version_path="$2"
    local plist_file=""
    
    if [[ "$path" == *.app ]]; then
        if [ "$is_ios_app" == true ]; then
            plist_file="$path/Info.plist"
        else
            plist_file="$path/Contents/Info.plist"
        fi
    elif [[ "$path" == *.framework ]]; then
        local framework_path="$(get_framework_path "$path" "$version_path")"
        
        if [ "$is_ios_app" == true ]; then
            plist_file="$framework_path/Info.plist"
        else
            plist_file="$framework_path/Resources/Info.plist"
        fi
    fi
    
    echo "$plist_file"
}

# Add an HTML <div> element with the `card` class
function add_html_card_container() {
    local card="$1"
    
    report_content="$report_content<div class=\"card\">$card</div>"
}

# Generate an HTML <h2> element
function generate_html_header() {
    local title="$1"
    local version="$2"
    
    echo "<h2>$title<span class=\"version\">Version $version</span></h2>"
}

# Generate an HTML <a> element with optional `warning` class
function generate_html_anchor() {
    local text="$1"
    local href="$2"
    local warning="$3"
    
    if [ "$warning" == true ]; then
        echo "<a class=\"warning\" href=\"$href\">$text</a>"
    else
        echo "<a href=\"$href\">$text</a>"
    fi
}

# Generate an HTML <table> element
function generate_html_table() {
    local thead="$1"
    local tbody="$2"
    
    echo "<table>$thead$tbody</table>"
}

# Generate an HTML <thead> element
function generate_html_thead() {
    local ths=("$@")
    local tr=""
    
    for th in "${ths[@]}"; do
        tr="$tr<th>$th</th>"
    done
    
    echo "<thead><tr>$tr</tr></thead>"
}

# Generate an HTML <tbody> element
function generate_html_tbody() {
    local trs=("$@")
    local tbody=""
    
    for tr in "${trs[@]}"; do
        tbody="$tbody<tr>"
        local tds=($(split_string_by_delimiter "$tr"))
        
        for td in "${tds[@]}"; do
            tbody="$tbody<td>$td</td>"
        done
        
        tbody="$tbody</tr>"
    done
    
    echo "<tbody>$tbody</tbody>"
}

# Generate the report content for the specified directory
function generate_report_content() {
    local path="$1"
    local version_path="$2"
    local privacy_manifest_file=""
    
    if [[ "$path" == *.app ]]; then
        # Per the documentation, the privacy manifest should be placed at the root of the app’s bundle for iOS, while for macOS, it should be located in `Contents/Resources/` within the app’s bundle
        # Reference: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk#Add-a-privacy-manifest-to-your-app
        if [ "$is_ios_app" == true ]; then
            privacy_manifest_file="$path/$PRIVACY_MANIFEST_FILE_NAME"
        else
            privacy_manifest_file="$path/Contents/Resources/$PRIVACY_MANIFEST_FILE_NAME"
        fi
    else
        # Per the documentation, the privacy manifest should be placed at the root of the iOS framework, while for a macOS framework with multiple versions, it should be located in the `Resources` directory within the corresponding version
        # Some SDKs don’t follow the guideline, so we use a search-based approach for now
        # Reference: https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk#Add-a-privacy-manifest-to-your-framework
        local framework_path="$(get_framework_path "$path" "$version_path")"
        local privacy_manifest_files=($(search_privacy_manifest_files "$framework_path"))
        privacy_manifest_file="$(get_privacy_manifest_file "${privacy_manifest_files[@]}")"
    fi
    
    local name="$(basename "$path")"
    local title="$name"
    if [ -n "$version_path" ]; then
        title="$name ($version_path)"
    fi
    
    local plist_file="$(get_plist_file "$path" "$version_path")"
    local version="$(get_plist_version "$plist_file")"
    local card="$(generate_html_header "$title" "$version")"
    
    if [ -f "$privacy_manifest_file" ]; then
        card="$card$(generate_html_anchor "$PRIVACY_MANIFEST_FILE_NAME" "$privacy_manifest_file" false)"
        
        local used_template_file="$(get_used_template_file "$name$version_path")"
        
        if [ -f "$used_template_file" ]; then
            card="$card$(generate_html_anchor "Template Used: $(basename "$used_template_file")" "$used_template_file" false)"
        fi
        
        local trs=($(analyze_privacy_accessed_api "$privacy_manifest_file"))
        
        # Generate table only if the accessed privacy API types array is not empty
        if [[ ${#trs[@]} -gt 0 ]]; then
            local thead="$(generate_html_thead "NSPrivacyAccessedAPIType" "NSPrivacyAccessedAPITypeReasons")"
            local tbody="$(generate_html_tbody "${trs[@]}")"
            
            card="$card$(generate_html_table "$thead" "$tbody")"
        fi
    else
        card="$card$(generate_html_anchor "Missing Privacy Manifest" "$path" true)"
    fi
    
    add_html_card_container "$card"
}

# Generate the report content for app
function generate_app_report_content() {
    generate_report_content "$app_path" ""
}

# Generate the report content for frameworks
function generate_frameworks_report_content() {
    if ! [ -d "$frameworks_dir" ]; then
        return
    fi
    
    for path in "$frameworks_dir"/*; do
        if [ -d "$path" ]; then
            local versions_dir="$path/Versions"
            
            if [ -d "$versions_dir" ]; then
                for version in $(ls -1 "$versions_dir" | grep -vE '^Current$'); do
                    local version_path="Versions/$version"
                    generate_report_content "$path" "$version_path"
                done
            else
                generate_report_content "$path" ""
            fi
        fi
    done
}

# Generate the final report with all content
function generate_final_report() {
    # Replace placeholders in the template with the tool's version and report content
    sed -i "" -e "s|{{TOOL_VERSION}}|$tool_version|g" -e "s|{{REPORT_CONTENT}}|${report_content}|g" "$report_output_file"
    
    echo "Privacy Access Report has been generated: $report_output_file"
}

generate_app_report_content
generate_frameworks_report_content
generate_final_report
