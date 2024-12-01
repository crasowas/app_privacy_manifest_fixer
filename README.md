# App Privacy Manifest Fixer

[![Latest Version](https://img.shields.io/github/v/release/crasowas/app_privacy_manifest_fixer?logo=github)](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

This shell-based tool is designed to analyze and update privacy manifests in iOS apps, ensuring compliance with App Store requirements, with its API usage analysis implemented based on the [app_store_required_privacy_manifest_analyser](https://github.com/crasowas/app_store_required_privacy_manifest_analyser).

> **Note:** Privacy manifests should ideally be maintained by third-party SDK developers.
> Use this tool primarily in the following scenarios:
> 1. The SDK has been deprecated and is no longer maintained.
> 2. The latest SDK version is incompatible with your iOS project.
> 3. The SDK does not provide a privacy manifest.
> 4. Frameworks that are not standalone SDKs but are generated as part of the build process, such as `App.framework` in `Flutter` projects.
> 5. Dependencies of the SDK have the issues mentioned above, and these cannot be resolved by upgrading the main SDK.

## Features

- **Seamless Integration**: Easily integrates or uninstalls from your iOS project.
- **Automated Analysis**: Analyzes API usage and updates privacy manifests during the build process.
- **Custom Templates**: Supports customizable privacy manifest templates for apps, generic frameworks, and specific frameworks.
- **Easy Upgrades**: Includes a script for upgrading the tool to the latest version.

## Installation Guide

### Download the Latest Version

1. Download the [latest release](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest).
2. Extract the downloaded archive and place the folder in your iOS project directory for better portability.

### Install the Tool

Run the following command to integrate the tool into your project:

```shell
sh install.sh <project_path>
```

#### Command Line Options

- **Force overwrite existing privacy manifests** (not recommended): Use the `-f` option to overwrite existing privacy manifests.

  ```shell
  sh install.sh <project_path> -f
  ```

- **Run only during install builds** (recommended): Use the `--install-builds-only` option to ensure the tool runs exclusively during install builds (e.g., Archive operations), improving development build performance.

  ```shell
  sh install.sh <project_path> --install-builds-only
  ```

### Uninstall the Tool

To remove the tool, run the following command:

```shell
sh uninstall.sh <project_path>
```

## Usage

Once installed, the tool runs automatically during each project build.

If installed with the `--install-builds-only` option, the tool runs only during project install builds.

### Upgrade the Tool

To update to the latest version, run the following command:

```shell
sh upgrade.sh
```

## Privacy Manifest Templates

Privacy manifest templates are stored in the [Templates](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates) directory. Custom templates can be added to the `UserTemplates` subdirectory, which has a higher priority during processing.

### Template Types

Templates are categorized as follows:

- **AppTemplate.xcprivacy**: A privacy manifest template for the app.
- **FrameworkTemplate.xcprivacy**: A generic privacy manifest template for frameworks.
- **FrameworkName.xcprivacy**: A privacy manifest template for a specific framework, available only in the `UserTemplates` directory.

### Template Priority

For apps, the privacy manifest template priority is as follows:

- `Templates/UserTemplates/AppTemplate.xcprivacy` > `Templates/AppTemplate.xcprivacy`

For a specific framework, the privacy manifest template priority is as follows:

- `Templates/UserTemplates/FrameworkName.xcprivacy` > `Templates/UserTemplates/FrameworkTemplate.xcprivacy` > `Templates/FrameworkTemplate.xcprivacy`

### Default Templates

The default templates are located in the `Templates` root directory and currently include the following templates:

- `Templates/AppTemplate.xcprivacy`
- `Templates/FrameworkTemplate.xcprivacy`

These templates will be modified based on the API usage analysis results. Specifically, the `NSPrivacyAccessedAPIType` entries in the templates will be adjusted to generate a new privacy manifest for the app or framework's privacy compliance.

**If you need to make any adjustments to the privacy manifest templates, such as the following scenarios, please avoid modifying the default templates directly. Instead, use custom templates. If a custom template with the same name exists, it will take precedence over the default template.**

- Generating a non-compliant privacy manifest due to inaccurate API usage analysis.
- Modifying the reason declared in the template.
- Adding declarations for collected data.

The API categories and their associated reasons in `AppTemplate.xcprivacy` are listed below:

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons        |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | C617.1: Inside app or group container  |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device         |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device         |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | CA92.1: Access info from same app      |

The API categories and their associated reasons in `FrameworkTemplate.xcprivacy` are listed below:

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons         |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | 0A2A.1: 3rd-party SDK wrapper on-device |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device          |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device  |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device          |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | C56D.1: 3rd-party SDK wrapper on-device |

### Custom Templates

To create custom templates, place them in the `UserTemplates` directory with the following structure:

- `Templates/UserTemplates/AppTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkName.xcprivacy`

Among these templates, only `FrameworkTemplate.xcprivacy` will be modified based on the API usage analysis results to adjust the `NSPrivacyAccessedAPIType` entries, thereby generating a new privacy manifest for framework fixes. The other templates will remain unchanged and will be directly used for fixes.

**Important Notes:**

- Specific framework templates must follow the naming convention `FrameworkName.xcprivacy`, where `FrameworkName` matches the framework's name. For example, the `Flutter` framework template should be named `Flutter.xcprivacy`.
- The SDK name may not always match the framework name. To identify the correct framework name, check the Application Bundle after building your project.

## Important Considerations

- Whenever possible, upgrade to the latest SDK version that supports privacy manifests to avoid unnecessary risks.
- This tool is a temporary solution and should not replace proper SDK management practices.
- Before submitting your app, ensure that the privacy manifests comply with the latest App Store requirements.
