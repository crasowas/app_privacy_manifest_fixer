#!/bin/bash

# Copyright (c) 2024, crasowas.
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

# Force replace the existing privacy manifest when the `-f` option is enabled
force=false

# Enable silent mode to disable build output when the `-s` option is enabled
silent=false

# Parse command-line options
while getopts ":fs" opt; do
    case $opt in
        f)
            force=true
            ;;
        s)
            silent=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

# Path of the app produced by the build process
app_path="${TARGET_BUILD_DIR}/${WRAPPER_NAME}"

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

# Default template directories
templates_dir="$tool_root_path/Templates"
user_templates_dir="$tool_root_path/Templates/UserTemplates"

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

# Disable build output in silent mode
if [ "$silent" == false ]; then
    # Script used to generate the privacy access report
    report_script="$tool_root_path/Report/report.sh"
    # An array to record template usage for generating the privacy access report
    template_usage_records=()
    
    # Build output directory
    build_dir="$tool_root_path/Build/${PRODUCT_NAME}-${CONFIGURATION}_${MARKETING_VERSION}_${CURRENT_PROJECT_VERSION}_$(date +%Y%m%d%H%M%S)"
    # Ensure the build directory exists
    mkdir -p "$build_dir"

    # Redirect both stdout and stderr to a log file while keeping console output
    exec > >(tee "$build_dir/fix.log") 2>&1
fi

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

# Get the path to the executable for the specified app or framework
function get_executable_path() {
    local path="$1"
    local version_path="$2"
    local executable_path=""
    
    local plist_file="$(get_plist_file "$path" "$version_path")"
    local executable_name="$(get_plist_executable "$plist_file")"
    
    if [[ "$path" == *.app ]]; then
        if [ "$is_ios_app" == true ]; then
            executable_path="$path/$executable_name"
        else
            executable_path="$path/Contents/MacOS/$executable_name"
        fi
    elif [[ "$path" == *.framework ]]; then
        local framework_path="$(get_framework_path "$path" "$version_path")"
        executable_path="$framework_path/$executable_name"
    fi
    
    echo "$executable_path"
}

# Analyze the specified binary file for API symbols and their categories
function analyze_binary_file() {
    local path="$1"
    local -a results=()

    # Check if the API symbol exists in the binary file using `nm` and `strings`
    local nm_output=$(nm "$path" 2>/dev/null | xcrun swift-demangle)
    local strings_output=$(strings "$path")
    local combined_output="$nm_output"$'\n'"$strings_output"

    for api_symbol in "${API_SYMBOLS[@]}"; do
        local substrings=($(split_string_by_delimiter "$api_symbol"))
        local category=${substrings[0]}
        local api=${substrings[1]}

        if echo "$combined_output" | grep -E "$api\$" >/dev/null; then
            local index=-1
            for ((i=0; i < ${#results[@]}; i++)); do
                local result="${results[i]}"
                local result_substrings=($(split_string_by_delimiter "$result"))
                # If the category matches an existing result, update it
                if [ "$category" == "${result_substrings[0]}" ]; then
                    index=i
                    results[i]="${result_substrings[0]}$DELIMITER${result_substrings[1]},$api$DELIMITER${result_substrings[2]}"
                    break
                fi
            done

            # If no matching category found, add a new result
            if [[ $index -eq -1 ]]; then
                results+=("$category$DELIMITER$api$DELIMITER$(encode_path "$path")")
            fi
        fi
    done
    
    echo "${results[@]}"
}

# Analyze API usage in a binary file
function analyze_api_usage() {
    local path="$1"
    local version_path="$2"
    local -a results=()
    
    local binary_file="$(get_executable_path "$path" "$version_path")"
    
    if [ -f "$binary_file" ]; then
        results+=($(analyze_binary_file "$binary_file"))
    fi

    echo "${results[@]}"
}



# Get unique categories from analysis results
function get_categories() {
    local results=("$@")
    local -a categories=()
    
    for result in "${results[@]}"; do
        local substrings=($(split_string_by_delimiter "$result"))
        local category=${substrings[0]}
        if [[ ! "${categories[@]}" =~ "$category" ]]; then
            categories+=("$category")
        fi
    done
    
    echo "${categories[@]}"
}

# Get template file for the specified app or framework
function get_template_file() {
    local path="$1"
    local version_path="$2"
    local template_file=""
    
    if [[ "$path" == *.app ]]; then
        template_file="$app_template_file"
    else
        # Give priority to the user-defined framework privacy manifest template
        local dep_name="$(get_dependency_name "$path")"
        if [ -n "$version_path" ]; then
            dep_name="$dep_name.$(basename "$version_path")"
        fi
        
        local dep_template_file="$user_templates_dir/${dep_name}.xcprivacy"
        if [ -f "$dep_template_file" ]; then
            template_file="$dep_template_file"
        else
            template_file="$framework_template_file"
        fi
    fi
    
    echo "$template_file"
}

# Check if the specified template file should be modified
#
# The following template files will be modified based on analysis:
# * Templates/AppTemplate.xcprivacy
# * Templates/FrameworkTemplate.xcprivacy
# * Templates/UserTemplates/FrameworkTemplate.xcprivacy
function is_template_modifiable() {
    local template_file="$1"
    
    local template_file_name="$(basename "$template_file")"

    if [[ "$template_file" != "$user_templates_dir"* ]] || [ "$template_file_name" == "$FRAMEWORK_TEMPLATE_FILE_NAME" ]; then
        return 0
    else
        return 1
    fi
}

# Check if `Hardened Runtime` is enabled for the specified path
function is_hardened_runtime_enabled() {
    local path="$1"

    # Check environment variable first
    if [ "${ENABLE_HARDENED_RUNTIME:-}" == "YES" ]; then
        return 0
    fi

    # Check the code signature flags if environment variable is not set
    local flags=$(codesign -dvvv "$path" 2>&1 | grep "flags=")
    if echo "$flags" | grep -q "runtime"; then
        return 0
    else
        return 1
    fi
}

# Re-sign the target app or framework if code signing is enabled
function resign() {
    local path="$1"

    if [ -n "${EXPANDED_CODE_SIGN_IDENTITY:-}" ] && [ "${CODE_SIGNING_REQUIRED:-}" != "NO" ] && [ "${CODE_SIGNING_ALLOWED:-}" != "NO" ]; then
        echo "Re-signing $path with Identity ${EXPANDED_CODE_SIGN_IDENTITY_NAME:-$EXPANDED_CODE_SIGN_IDENTITY}"

        local codesign_cmd="/usr/bin/codesign --force --sign ${EXPANDED_CODE_SIGN_IDENTITY} ${OTHER_CODE_SIGN_FLAGS:-} --preserve-metadata=identifier,entitlements"

        if [ "$is_ios_app" == true ]; then
            $codesign_cmd "$path"
        else
            if is_hardened_runtime_enabled "$path"; then
                codesign_cmd="$codesign_cmd -o runtime"
            fi
            
            if [ -d "$path/Contents/MacOS" ]; then
                find "$path/Contents/MacOS" -type f -name "*.dylib" | while read -r dylib_file; do
                    $codesign_cmd "$dylib_file"
                done
            fi
            
            $codesign_cmd "$path"
        fi
    fi
}

# Fix the privacy manifest for the app or specified framework
# To accelerate the build, existing privacy manifests will be left unchanged unless the `-f` option is enabled
# After fixing, the app or framework will be automatically re-signed
function fix() {
    local path="$1"
    local version_path="$2"
    local force_resign="$3"
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
        
        if [ -z "$privacy_manifest_file" ]; then
            if [ "$is_ios_app" == true ]; then
                privacy_manifest_file="$framework_path/$PRIVACY_MANIFEST_FILE_NAME"
            else
                privacy_manifest_file="$framework_path/Resources/$PRIVACY_MANIFEST_FILE_NAME"
            fi
        fi
    fi
    
    # Check if the privacy manifest file exists
    if [ -f "$privacy_manifest_file" ]; then
        echo "💡 Found privacy manifest file: $privacy_manifest_file"
        
        if [ "$force" == false ]; then
            if [ "$force_resign" == true ]; then
                resign "$path"
            fi
            echo "✅ Privacy manifest file already exists, skipping fix."
            return
        fi
    else
        echo "⚠️  Missing privacy manifest file!"
    fi
    
    local results=($(analyze_api_usage "$path" "$version_path"))
    echo "API usage analysis result(s): ${#results[@]}"
    print_array "${results[@]}"
    
    local template_file="$(get_template_file "$path" "$version_path")"
    template_usage_records+=("$(basename "$path")$version_path$DELIMITER$template_file")
    
    # Copy the template file to the privacy manifest location, overwriting if it exists
    cp "$template_file" "$privacy_manifest_file"
    
    if is_template_modifiable "$template_file"; then
        local categories=($(get_categories "${results[@]}"))
        local remove_categories=()
        
        # Check if categories is non-empty
        if [[ ${#categories[@]} -gt 0 ]]; then
            # Convert categories to a single space-separated string for easy matching
            local categories_set=" ${categories[*]} "
            
            # Iterate through each element in `API_CATEGORIES`
            for element in "${API_CATEGORIES[@]}"; do
                # If element is not found in `categories_set`, add it to `remove_categories`
                if [[ ! $categories_set =~ " $element " ]]; then
                    remove_categories+=("$element")
                fi
            done
        else
            # If categories is empty, add all of `API_CATEGORIES` to `remove_categories`
            remove_categories=("${API_CATEGORIES[@]}")
        fi

        # Remove extra spaces in the XML file to simplify node removal
        xmllint --noblanks "$privacy_manifest_file" -o "$privacy_manifest_file"

        # Build a sed command to remove all matching nodes at once
        local sed_pattern=""
        for category in "${remove_categories[@]}"; do
            # Find the node for the current category
            local remove_node="$(xmllint --xpath "//dict[string='$category']" "$privacy_manifest_file" 2>/dev/null || true)"
            
            # If the node is found, escape special characters and append it to the sed pattern
            if [ -n "$remove_node" ]; then
                local escaped_node=$(echo "$remove_node" | sed 's/[\/&]/\\&/g')
                sed_pattern+="s/$escaped_node//g;"
            fi
        done

        # Apply the combined sed pattern to the file if it's not empty
        if [ -n "$sed_pattern" ]; then
            sed -i "" "$sed_pattern" "$privacy_manifest_file"
        fi

        # Reformat the XML file to restore spaces for readability
        xmllint --format "$privacy_manifest_file" -o "$privacy_manifest_file"
    fi
    
    resign "$path"
    
    echo "✅ Privacy manifest file fixed: $privacy_manifest_file."
}

# Fix privacy manifests for all frameworks
function fix_frameworks() {
    if ! [ -d "$frameworks_dir" ]; then
        return
    fi
    
    echo "🛠️ Fixing Frameworks..."
    for path in "$frameworks_dir"/*; do
        if [ -d "$path" ]; then
            local dep_name="$(get_dependency_name "$path")"
            local versions_dir="$path/Versions"
            
            if [ -d "$versions_dir" ]; then
                for version in $(ls -1 "$versions_dir" | grep -vE '^Current$'); do
                    local version_path="Versions/$version"
                    echo "Analyzing $dep_name ($version_path) ..."
                    fix "$path" "$version_path" false
                    echo ""
                done
            else
                echo "Analyzing $dep_name ..."
                fix "$path" "" false
                echo ""
            fi
        fi
    done
}

# Fix the privacy manifest for the app
function fix_app() {
    echo "🛠️ Fixing $(basename "$app_path" .app) App..."
    # Since the framework may have undergone fixes, the app must be forcefully re-signed
    fix "$app_path" "" true
    echo ""
}

# Generate the privacy access report for the app
function generate_report() {
    local original="$1"
    
    if [ "$silent" == true ]; then
        return
    fi

    local app_name="$(basename "$app_path")"
    local name="${app_name%.*}"
    local report_name=""

    # Adjust output names if the app is flagged as original
    if [ "$original" == true ]; then
        app_name="${name}-original.app"
        report_name="report-original.html"
    else
        app_name="$name.app"
        report_name="report.html"
    fi
    
    local target_app_path="$build_dir/$app_name"
    local report_path="$build_dir/$report_name"
    
    echo "Copy app to $target_app_path"
    rsync -a "$app_path/" "$target_app_path/"
    
    # Generate the privacy access report using the script
    sh "$report_script" "$target_app_path" "$report_path" "${template_usage_records[@]}"
    echo ""
}

start_time=$(date +%s)

generate_report true
fix_frameworks
fix_app
generate_report false

end_time=$(date +%s)

echo "🎉 All fixed! ⏰ $((end_time - start_time)) seconds"
echo "🌟 If you found this script helpful, please consider giving it a star on GitHub. Your support is appreciated. Thank you!"
echo "🔗 Homepage: https://github.com/crasowas/app_privacy_manifest_fixer"
echo "🐛 Report issues: https://github.com/crasowas/app_privacy_manifest_fixer/issues"
