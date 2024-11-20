#!/bin/bash

# Copyright (c) 2024, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

# Force replace the existing privacy manifest when the `-f` option is enabled
force=false

# Parse command-line options
while getopts ":f" opt; do
  case $opt in
    f) force=true
    ;;
    \?) echo "Invalid option: -$OPTARG" >&2
        exit 1
    ;;
  esac
done

shift $((OPTIND - 1))

# Directory of the app generated after the build
app_dir="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"
frameworks_dir="$app_dir/Frameworks"

# Check if the app exists
if [ ! -d "$app_dir" ]; then
    echo "Unable to find the app: $app_dir"
    exit 1
fi

# Absolute path of the script and the fixer directory
script_path="$(realpath "$0")"
fixer_dir="$(dirname "$script_path")"

# Default template paths
templates_dir="$fixer_dir/Templates"
user_templates_dir="$fixer_dir/Templates/UserTemplates"

# Common privacy manifest template file names
readonly APP_TEMPLATE_FILE_NAME="AppTemplate.xcprivacy"
readonly FRAMEWORK_TEMPLATE_FILE_NAME="FrameworkTemplate.xcprivacy"

# Use user-defined app privacy manifest template if it exists, otherwise fallback to default
app_template_file="$user_templates_dir/$APP_TEMPLATE_FILE_NAME"
if [ ! -f "$app_template_file" ]; then
    app_template_file="$templates_dir/$APP_TEMPLATE_FILE_NAME"
fi

# Use user-defined framework privacy manifest template if it exists, otherwise fallback to default
framework_template_file="$user_templates_dir/$FRAMEWORK_TEMPLATE_FILE_NAME"
if [ ! -f "$framework_template_file" ]; then
    framework_template_file="$templates_dir/$FRAMEWORK_TEMPLATE_FILE_NAME"
fi

# File name of the privacy manifest
readonly PRIVACY_MANIFEST_FILE_NAME="PrivacyInfo.xcprivacy"

# Universal delimiter
readonly DELIMITER=":"

# Space escape symbol for handling space in path
readonly SPACE_ESCAPE="\u0020"

# Categories of required reason APIs
readonly API_CATEGORIES=(
    "NSPrivacyAccessedAPICategoryFileTimestamp"
    "NSPrivacyAccessedAPICategorySystemBootTime"
    "NSPrivacyAccessedAPICategoryDiskSpace"
    "NSPrivacyAccessedAPICategoryActiveKeyboards"
    "NSPrivacyAccessedAPICategoryUserDefaults"
)

# Symbol of the required reason APIs and their categories
# See also:
#   * https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
#   * https://github.com/Wooder/ios_17_required_reason_api_scanner/blob/main/required_reason_api_binary_scanner.sh
readonly API_SYMBOLS=(
    # NSPrivacyAccessedAPICategoryFileTimestamp
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}getattrlist"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}getattrlistbulk"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}fgetattrlist"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}stat"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}fstat"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}fstatat"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}lstat"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}getattrlistat"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}NSFileCreationDate"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}NSFileModificationDate"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}NSURLContentModificationDateKey"
    "NSPrivacyAccessedAPICategoryFileTimestamp${DELIMITER}NSURLCreationDateKey"
    # NSPrivacyAccessedAPICategorySystemBootTime
    "NSPrivacyAccessedAPICategorySystemBootTime${DELIMITER}systemUptime"
    "NSPrivacyAccessedAPICategorySystemBootTime${DELIMITER}mach_absolute_time"
    # NSPrivacyAccessedAPICategoryDiskSpace
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}statfs"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}statvfs"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}fstatfs"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}fstatvfs"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSFileSystemFreeSize"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSFileSystemSize"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSURLVolumeAvailableCapacityKey"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSURLVolumeAvailableCapacityForImportantUsageKey"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSURLVolumeAvailableCapacityForOpportunisticUsageKey"
    "NSPrivacyAccessedAPICategoryDiskSpace${DELIMITER}NSURLVolumeTotalCapacityKey"
    # NSPrivacyAccessedAPICategoryActiveKeyboards
    "NSPrivacyAccessedAPICategoryActiveKeyboards${DELIMITER}activeInputModes"
    # NSPrivacyAccessedAPICategoryUserDefaults
    "NSPrivacyAccessedAPICategoryUserDefaults${DELIMITER}NSUserDefaults"
)

# Print the elements of an array along with their indices
print_array() {
    local -a array=("$@")
    
    for ((i=0; i<${#array[@]}; i++)); do
        echo "[$i] $(decode_path "${array[i]}")"
    done
}

# Split a string into substrings using a specified delimiter
split_string_by_delimiter() {
    local string="$1"
    local -a substrings=()

    IFS="$DELIMITER" read -ra substrings <<< "$string"

    echo "${substrings[@]}"
}

# Encode a path string by replacing space with an escape character
encode_path() {
    echo "$1" | sed "s/ /$SPACE_ESCAPE/g";
}

# Decode a path string by replacing encoded character with space
decode_path() {
    echo "$1" | sed "s/$SPACE_ESCAPE/ /g";
}

get_dependency_name() {
    local dep_path="$1"
    local dir_name="$(basename "$dep_path")"

    # Remove .app, .framework, and .xcframework suffixes
    local dep_name="${dir_name%.*}"
    
    echo "$dep_name"
}

# Analyze the specified binary file for API symbols and their categories
analyze_binary_file() {
    local file_path="$1"
    local -a results=()
    
    for api_symbol in "${API_SYMBOLS[@]}"; do
        substrings=($(split_string_by_delimiter "$api_symbol"))
        category=${substrings[0]}
        api=${substrings[1]}
    
        # Check if the API symbol exists in the binary file
        if nm "$file_path" 2>/dev/null | xcrun swift-demangle | grep -E "$api$" >/dev/null; then
            index=-1
            for ((i=0; i<${#results[@]}; i++)); do
                result="${results[i]}"
                result_substrings=($(split_string_by_delimiter "$result"))
                # If the category matches an existing result, update it
                if [ "$category" == "${result_substrings[0]}" ]; then
                   index=i
                   results[i]="${result_substrings[0]}$DELIMITER${result_substrings[1]},$api$DELIMITER${result_substrings[2]}"
                   break
                fi
            done
  
            # If no matching category found, add a new result
            if [[ $index -eq -1 ]]; then
                results+=("$category$DELIMITER$api$DELIMITER$(encode_path "$file_path")")
            fi
        fi
    done
    
    echo "${results[@]}"
}

# Analyze API usage in a binary file
analyze_api_usage() {
    local dir_path="$1"
    local -a results=()
    
    local dir_name="$(basename "$dir_path")"
    
    binary_name="${dir_name%.*}"
    binary_file="$dir_path/$binary_name"
    
    if [ -f "$binary_file" ]; then
        results+=($(analyze_binary_file "$binary_file"))
    fi

    echo "${results[@]}"
}

# Search for privacy manifest files in a directory
search_privacy_manifest_files() {
    local dir_path="$1"
    local -a privacy_manifest_files=()

    # Create a temporary file to store search results
    local temp_file="$(mktemp)"

    # Ensure the temporary file is deleted on script exit
    trap "rm -f $temp_file" EXIT

    # Find privacy manifest files within the specified directory and store the results in the temporary file
    find "$dir_path" -type f -name "$PRIVACY_MANIFEST_FILE_NAME" -print0 2>/dev/null > "$temp_file"

    while IFS= read -r -d '' file_path; do
        privacy_manifest_files+=($(encode_path "$file_path"))
    done < "$temp_file"

    echo "${privacy_manifest_files[@]}"
}

get_privacy_manifest_file() {
    # If there are multiple privacy manifest files, return the one with the shortest path
    local privacy_manifest_file="$(printf "%s\n" "$@" | awk '{print length, $0}' | sort -n | head -n1 | cut -d ' ' -f2-)"
    
    echo "$(decode_path "$privacy_manifest_file")"
}

# Get unique categories from analysis results
get_categories() {
    local results=("$@")
    local -a categories=()
    
    for result in "${results[@]}"; do
        substrings=($(split_string_by_delimiter "$result"))
        category=${substrings[0]}
        if [[ ! "${categories[@]}" =~ "$category" ]]; then
            categories+=("$category")
        fi
    done
    
    echo "${categories[@]}"
}

# Get template file for the specified app or framework
get_template_file() {
    local dir_path="$1"
    local template_file=""
    
    if [[ "$dir_path" == *.app ]]; then
        template_file="$app_template_file"
    else
        # Give priority to the user-defined framework privacy manifest template
        dep_name="$(get_dependency_name "$dir_path")"
        dep_template_file="$user_templates_dir/${dep_name}.xcprivacy"
        if [ -f "$dep_template_file" ]; then
            template_file="$dep_template_file"
        else
            template_file="$framework_template_file"
        fi
    fi
    
    echo "$template_file"
}

# Copy the template file to the privacy manifest location, overwriting if it exists
# If the privacy manifest file doesn't exist, copy it to the root directory of the app or framework by default
copy_template_file() {
    local dir_path="$1"
    local template_file="$2"
    local privacy_manifest_file="$3"
    
    if [ -z "$privacy_manifest_file" ]; then
        privacy_manifest_file="$dir_path/$PRIVACY_MANIFEST_FILE_NAME"
    fi
    
    cp "$template_file" "$privacy_manifest_file"
    echo "$privacy_manifest_file"
}

# Check if the specified template file should be modified
#
# The following template files will be modified based on analysis:
# * Templates/AppTemplate.xcprivacy
# * Templates/FrameworkTemplate.xcprivacy
# * Templates/UserTemplates/FrameworkTemplate.xcprivacy
is_template_modifiable() {
    local template_file="$1"
    
    local template_file_name="$(basename "$template_file")"

    if [[ "$template_file" != "$user_templates_dir"* ]] || [ "$template_file_name" == "$FRAMEWORK_TEMPLATE_FILE_NAME" ]; then
        return 0
    else
        return 1
    fi
}

# Re-sign the target app or framework if code signing is enabled
resign() {
  if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "${CODE_SIGNING_REQUIRED:-}" != "NO" ] && [ "${CODE_SIGNING_ALLOWED}" != "NO" ]; then
    echo "Re-signing $1 with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME}"
    /usr/bin/codesign --force --sign "${EXPANDED_CODE_SIGN_IDENTITY}" ${OTHER_CODE_SIGN_FLAGS:-} --preserve-metadata=identifier,entitlements "$1"
  fi
}

# Fix the privacy manifest for the app or specified framework
# To accelerate the build, existing privacy manifests will be left unchanged unless the `-f` option is enabled
# After fixing, the app or framework will be automatically re-signed
fix() {
    local dir_path="$1"
    local force_resign="$2"
    
    privacy_manifest_files=($(search_privacy_manifest_files "$dir_path"))
    privacy_manifest_file="$(get_privacy_manifest_file "${privacy_manifest_files[@]}")"
    
    # Check if the privacy manifest file exists
    if [ -f "$privacy_manifest_file" ]; then
        echo "💡 Found privacy manifest file: $privacy_manifest_file"
        
        if [ "$force" == false ]; then
            if [ "$force_resign" == true ]; then
                resign "$dir_path"
            fi
            echo "✅ Privacy manifest file already exists, skipping fix."
            return
        fi
    else
        echo "⚠️  Missing privacy manifest file!"
    fi
    
    results=($(analyze_api_usage "$dir_path"))
    echo "API usage analysis result(s): ${#results[@]}"
    print_array "${results[@]}"
    
    template_file="$(get_template_file "$dir_path")"
    privacy_manifest_file="$(copy_template_file "$dir_path" "$template_file" "$privacy_manifest_file")"
    
    if is_template_modifiable "$template_file"; then
        categories=($(get_categories "${results[@]}"))
        
        remove_categories=()
        # Check if categories is non-empty
        if [[ ${#categories[@]} -gt 0 ]]; then
            # Convert categories to a single space-separated string for easy matching
            categories_set=" ${categories[*]} "
            
            # Iterate through each element in API_CATEGORIES
            for element in "${API_CATEGORIES[@]}"; do
                # If element is not found in categories_set, add it to remove_categories
                if [[ ! $categories_set =~ " $element " ]]; then
                    remove_categories+=("$element")
                fi
            done
        else
            # If categories is empty, add all of API_CATEGORIES to remove_categories
            remove_categories=("${API_CATEGORIES[@]}")
        fi

        # Remove extra spaces in the XML file once for easier node removal
        xmllint --noblanks "$privacy_manifest_file" -o "$privacy_manifest_file"

        # Build a sed command to remove all matching nodes at once
        sed_pattern=""
        for category in "${remove_categories[@]}"; do
            # Find the node for the current category
            remove_node="$(xmllint --xpath "//dict[string='$category']" "$privacy_manifest_file" 2>/dev/null || true)"
            
            # If the node is found, escape special characters and append it to the sed pattern
            if [[ -n "$remove_node" ]]; then
                escaped_node=$(echo "$remove_node" | sed 's/[\/&]/\\&/g')
                sed_pattern+="s/$escaped_node//g;"
            fi
        done

        # Apply the combined sed pattern to the file if it's not empty
        if [[ -n "$sed_pattern" ]]; then
            sed -i "" "$sed_pattern" "$privacy_manifest_file"
        fi

        # Reformat the XML file to restore spaces for readability
        xmllint --format "$privacy_manifest_file" -o "$privacy_manifest_file"
    fi
    
    resign "$path"
    
    echo "✅ Privacy manifest file fixed: $privacy_manifest_file."
}

# Fix privacy manifests for all frameworks
fix_frameworks() {
    if ! [ -d "$frameworks_dir" ]; then
        return
    fi
    
    echo "🛠️ Fixing Frameworks..."
    for path in "$frameworks_dir"/*; do
        if [ -d "$path" ]; then
            dep_name="$(get_dependency_name "$path")"
            echo "Analyzing $dep_name ..."
            fix "$path" false
            echo ""
        fi
    done
}

# Fix the privacy manifest for the app
fix_app() {
    echo "🛠️ Fixing $(basename "$app_dir" .app) App..."
    # Since the framework may have undergone fixes, the app must be forcefully re-signed
    fix "$app_dir" true
}

fix_frameworks
fix_app

echo ""
echo "🎉 All fixed!"
echo "🌟 If you found this script helpful, please consider giving it a star on GitHub. Your support is appreciated. Thank you!"
echo "🔗 Homepage: https://github.com/crasowas/app_privacy_manifest_fixer"
echo "🐛 Report issues: https://github.com/crasowas/app_privacy_manifest_fixer/issues"

