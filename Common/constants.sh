#!/bin/bash

# Copyright (c) 2025, crasowas.
#
# Use of this source code is governed by a MIT-style license
# that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

set -e

# Prevent duplicate loading
if [ -n "$CONSTANTS_SH_LOADED" ]; then
    return
fi

readonly CONSTANTS_SH_LOADED=1

# File name of the privacy manifest
readonly PRIVACY_MANIFEST_FILE_NAME="PrivacyInfo.xcprivacy"

# Common privacy manifest template file names
readonly APP_TEMPLATE_FILE_NAME="AppTemplate.xcprivacy"
readonly FRAMEWORK_TEMPLATE_FILE_NAME="FrameworkTemplate.xcprivacy"

# Universal delimiter
readonly DELIMITER=":"

# Space escape symbol for handling space in path
readonly SPACE_ESCAPE="\u0020"

# Default value when the version cannot be retrieved
readonly UNKNOWN_VERSION="unknown"

# Categories of required reason APIs
readonly API_CATEGORIES=(
    "NSPrivacyAccessedAPICategoryFileTimestamp"
    "NSPrivacyAccessedAPICategorySystemBootTime"
    "NSPrivacyAccessedAPICategoryDiskSpace"
    "NSPrivacyAccessedAPICategoryActiveKeyboards"
    "NSPrivacyAccessedAPICategoryUserDefaults"
)

# Symbol of the required reason APIs and their categories
#
# See also:
#   * https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
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
