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

- **Seamless Integration**: Easily installs or uninstalls from your iOS project.
- **Automated Analysis**: Analyzes API usage and updates privacy manifests during the build process.
- **Privacy Access Report**: Easily review app and SDKs' privacy access details, along with the privacy manifest templates used for fixes.
- **Custom Templates**: Supports customizable privacy manifest templates for apps, generic frameworks, and specific frameworks.
- **Easy Upgrades**: Includes a script for upgrading the tool to the latest version.

## Installation Guide

### Download the Latest Version

1. **Download the [latest release](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest).**
2. **Extract the downloaded archive.** It is recommended to place the extracted directory in your iOS project directory. This approach helps avoid issues with absolute paths and ensures better portability when sharing the project or working on different devices.

### Install the Tool

Run the following command to install the tool into your project:

```shell
sh install.sh <project_path>
```

If the command is executed repeatedly, any existing installation will be automatically overwritten.

#### Command Line Options

- **Force overwrite existing privacy manifests (not recommended)**: Use the `-f` option to overwrite existing privacy manifests.

  ```shell
  sh install.sh <project_path> -f
  ```

- **Silent mode**: Use the `-s` option to disable build output, meaning the app will not be copied and the privacy access report will not be generated. When not enabled, the built app and its privacy access report will be saved to the `app_privacy_manifest_fixer/Build` directory.

  ```shell
  sh install.sh <project_path> -s
  ```

- **Run only during install builds (recommended)**: Use the `--install-builds-only` option to ensure the tool runs exclusively during install builds (e.g., Archive operations), improving development build performance.

  ```shell
  sh install.sh <project_path> --install-builds-only
  ```
  
  **Note: If the app is built in a development environment (with `*.debug.dylib` files), the tool's API usage analysis may be inaccurate.**

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

## Privacy Access Report

By default, silent mode is disabled, and the tool automatically generates privacy access reports for both the original and fixed versions of the app during each project build.

### Report Examples

| Original App Report                                                                            | Fixed App Report                                                                            |
|------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ![Original App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230746.png) | ![Fixed App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230822.png) |

### Generate a Report Manually

To manually generate a privacy access report for a specific app, run the following command:

```shell
sh Report/report.sh <app_path> <report_output_path>
# <app_path>: Path to the app (e.g., /path/to/App.app)
# <report_output_path>: Path to save the report file (e.g., /path/to/report.html)
```

## Privacy Manifest Templates

Privacy manifest templates are stored in the [`Templates`](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates) directory, which already includes default templates.

**How can you customize the privacy manifests for apps or SDKs? Simply use [custom templates](#custom-templates)!**

### Template Types

Templates are categorized as follows:

- **AppTemplate.xcprivacy**: A privacy manifest template for the app.
- **FrameworkTemplate.xcprivacy**: A generic privacy manifest template for frameworks.
- **FrameworkName.xcprivacy**: A privacy manifest template for a specific framework, available only in the `UserTemplates` directory.

### Template Priority

For an app, the priority of privacy manifest templates is as follows:

- `Templates/UserTemplates/AppTemplate.xcprivacy` > `Templates/AppTemplate.xcprivacy`

For a specific framework, the priority of privacy manifest templates is as follows:

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
- The SDK name may not always match the framework name. To identify the correct framework name, check the application bundle after building your project.

## Important Considerations

- Whenever possible, upgrade to the latest SDK version that supports privacy manifests to avoid unnecessary risks.
- This tool is a temporary solution and should not replace proper SDK management practices.
- Before submitting your app, ensure that the privacy manifests comply with the latest App Store requirements.
