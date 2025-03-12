# App Privacy Manifest Fixer

[![Latest Version](https://img.shields.io/github/v/release/crasowas/app_privacy_manifest_fixer?logo=github)](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)
![Supported Platforms](https://img.shields.io/badge/Supported%20Platforms-iOS%20%7C%20macOS-brightgreen)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**English | [简体中文](./README.zh-CN.md)**

This tool is an automation solution based on Shell scripts, designed to analyze and fix the privacy manifest of iOS/macOS apps to ensure compliance with App Store requirements. It leverages the [App Store Privacy Manifest Analyzer](https://github.com/crasowas/app_store_required_privacy_manifest_analyser) to analyze API usage within the app and its dependencies, and generate or fix the `PrivacyInfo.xcprivacy` file.

## ✨ Features

- **Non-Intrusive Integration**: No need to modify the source code or adjust the project structure.
- **Fast Installation and Uninstallation**: Quickly install or uninstall the tool with a single command.
- **Automatic Analysis and Fixes**: Automatically analyzes API usage and fixes privacy manifest issues during the project build.
- **Flexible Template Customization**: Supports custom privacy manifest templates for apps and frameworks, accommodating various usage scenarios.
- **Privacy Access Report**: Automatically generates a report displaying the `NSPrivacyAccessedAPITypes` declarations for the app and SDKs.
- **Effortless Version Upgrades**: Provides an upgrade script for quick updates to the latest version.

## 📥 Installation

### Download the Tool

1. Download the [latest release](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest).
2. Extract the downloaded file:
   - The extracted directory is usually named `app_privacy_manifest_fixer-xxx` (where `xxx` is the version number).
   - It is recommended to rename it to `app_privacy_manifest_fixer` or use the full directory name in subsequent paths.
   - **It is advised to move the directory to your iOS/macOS project to avoid path-related issues on different devices, and to easily customize the privacy manifest template for each project**.

### ⚡ Automatic Installation (Recommended)

1. **Navigate to the tool's directory**:

   ```shell
   cd /path/to/app_privacy_manifest_fixer
   ```

2. **Run the installation script**:

   ```shell
   sh install.sh <project_path>
   ```

   - For Flutter projects, `project_path` should be the path to the `ios/macos` directory within the Flutter project.
   - If the installation command is run again, the tool will first remove any existing installation (if present). To modify command-line options, simply rerun the installation command without the need to uninstall first.

### Manual Installation

If you prefer not to use the installation script, you can manually add the `Fix Privacy Manifest` task to the Xcode **Build Phases**. Follow these steps:

#### 1. Add the Script in Xcode

- Open your iOS/macOS project in Xcode, go to the **TARGETS** tab, and select your app target.
- Navigate to **Build Phases**, click the **+** button, and select **New Run Script Phase**.
- Rename the newly created **Run Script** to `Fix Privacy Manifest`.
- In the **Shell** script box, add the following code:

  ```shell
  # Use relative path (recommended): if `app_privacy_manifest_fixer` is within the project directory
  "$PROJECT_DIR/path/to/app_privacy_manifest_fixer/fixer.sh"

  # Use absolute path: if `app_privacy_manifest_fixer` is outside the project directory
  # "/absolute/path/to/app_privacy_manifest_fixer/fixer.sh"
  ```

  **Modify `path/to` or `absolute/path/to` as needed, and ensure the paths are correct. Remove or comment out the unused lines accordingly.**

#### 2. Adjust the Script Execution Order

**Move this script after all other Build Phases to ensure the privacy manifest is fixed after all resource copying and build tasks are completed**.

### Build Phases Screenshot

Below is a screenshot of the Xcode Build Phases configuration after successful automatic/manual installation (with no command-line options enabled):

![Build Phases Screenshot](https://img.crasowas.dev/app_privacy_manifest_fixer/20250225011407.png)

## 🚀 Getting Started

After installation, the tool will automatically run with each project build, and the resulting application bundle will include the fixes.

If the `--install-builds-only` command-line option is enabled during installation, the tool will only run during the installation of the build.

### Xcode Build Log Screenshot

Below is a screenshot of the log output from the tool during the project build (by default, it will be saved to the `app_privacy_manifest_fixer/Build` directory, unless the `-s` command-line option is enabled):

![Xcode Build Log Screenshot](https://img.crasowas.dev/app_privacy_manifest_fixer/20250225011551.png)

## 📖 Usage

### Command Line Options

- **Force overwrite existing privacy manifest (Not recommended)**:

  ```shell
  sh install.sh <project_path> -f
  ```

  Enabling the `-f` option will force the tool to generate a new privacy manifest based on the API usage analysis and privacy manifest template, overwriting the existing privacy manifest. By default (without `-f`), the tool only fixes missing privacy manifests.

- **Silent mode**:

  ```shell
  sh install.sh <project_path> -s
  ```

  Enabling the `-s` option disables output during the fix process. The tool will no longer copy the generated `*.app`, automatically generate the privacy access report, or output the fix logs. By default (without `-s`), these outputs are stored in the `app_privacy_manifest_fixer/Build` directory.

- **Run only during installation builds (Recommended)**:

  ```shell
  sh install.sh <project_path> --install-builds-only
  ```

  Enabling the `--install-builds-only` option makes the tool run only during installation builds (such as the **Archive** operation), optimizing build performance for daily development. If you manually installed, this option is ineffective, and you need to manually check the **For install builds only** option.

  **Note**: If the iOS/macOS project is built in a development environment (where the generated app contains `*.debug.dylib` files), the tool's API usage analysis results may be inaccurate.

### Upgrade the Tool

To update to the latest version, run the following command:

```shell
sh upgrade.sh
```

### Uninstall the Tool

To quickly uninstall the tool, use the following command:

```shell
sh uninstall.sh <project_path>
```

## 🔥 Privacy Manifest Templates

The privacy manifest templates are stored in the [`Templates`](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates) directory, with the default templates already included in the root directory.

**How can you customize the privacy manifests for apps or SDKs? Simply use [custom templates](#custom-templates)!**

### Template Types

The templates are categorized as follows:
- **AppTemplate.xcprivacy**: A privacy manifest template for the app.
- **FrameworkTemplate.xcprivacy**: A generic privacy manifest template for frameworks.
- **FrameworkName.xcprivacy**: A privacy manifest template for a specific framework, available only in the `Templates/UserTemplates` directory.

### Template Priority

For an app, the priority of privacy manifest templates is as follows:
- `Templates/UserTemplates/AppTemplate.xcprivacy` > `Templates/AppTemplate.xcprivacy`

For a specific framework, the priority of privacy manifest templates is as follows:
- `Templates/UserTemplates/FrameworkName.xcprivacy` > `Templates/UserTemplates/FrameworkTemplate.xcprivacy` > `Templates/FrameworkTemplate.xcprivacy`

### Default Templates

The default templates are located in the `Templates` root directory and currently include the following templates:
- `Templates/AppTemplate.xcprivacy`
- `Templates/FrameworkTemplate.xcprivacy`

These templates will be modified based on the API usage analysis results, especially the `NSPrivacyAccessedAPIType` entries, to generate new privacy manifests for fixes, ensuring compliance with App Store requirements.

**If adjustments to the privacy manifest template are needed, such as in the following scenarios, avoid directly modifying the default templates. Instead, use a custom template. If a custom template with the same name exists, it will take precedence over the default template for fixes.**
- Generating a non-compliant privacy manifest due to inaccurate API usage analysis.
- Modifying the reason declared in the template.
- Adding declarations for collected data.

The privacy access API categories and their associated declared reasons in `AppTemplate.xcprivacy` are listed below:

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons        |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | C617.1: Inside app or group container  |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device         |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device         |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | CA92.1: Access info from same app      |

The privacy access API categories and their associated declared reasons in `FrameworkTemplate.xcprivacy` are listed below:

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons         |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | 0A2A.1: 3rd-party SDK wrapper on-device |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device          |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device  |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device          |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | C56D.1: 3rd-party SDK wrapper on-device |

### Custom Templates

To create custom templates, place them in the `Templates/UserTemplates` directory with the following structure:
- `Templates/UserTemplates/AppTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkName.xcprivacy`

Among these templates, only `FrameworkTemplate.xcprivacy` will be modified based on the API usage analysis results to adjust the `NSPrivacyAccessedAPIType` entries, thereby generating a new privacy manifest for framework fixes. The other templates will remain unchanged and will be directly used for fixes.

**Important Notes:**
- The template for a specific framework must follow the naming convention `FrameworkName.xcprivacy`, where `FrameworkName` should match the name of the framework. For example, the template for `Flutter.framework` should be named `Flutter.xcprivacy`.
- For macOS frameworks, the naming convention should be `FrameworkName.Version.xcprivacy`, where the version name is added to distinguish different versions. For a single version macOS framework, the `Version` is typically `A`.
- The name of an SDK may not exactly match the name of the framework. To determine the correct framework name, check the `Frameworks` directory in the application bundle after building the project.

## 📑 Privacy Access Report

By default, the tool automatically generates privacy access reports for both the original and fixed versions of the app during each project build, and stores the reports in the `app_privacy_manifest_fixer/Build` directory.

If you need to manually generate a privacy access report for a specific app, run the following command:

```shell
sh Report/report.sh <app_path> <report_output_path>
# <app_path>: Path to the app (e.g., /path/to/App.app)
# <report_output_path>: Path to save the report file (e.g., /path/to/report.html)
```

**Note**: The report generated by the tool currently only includes the privacy access section (`NSPrivacyAccessedAPITypes`). To view the data collection section (`NSPrivacyCollectedDataTypes`), please use Xcode to generate the `PrivacyReport`.

### Sample Report Screenshots

| Original App Report (report-original.html)                                                     | Fixed App Report (report.html)                                                              |
|------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ![Original App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230746.png) | ![Fixed App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230822.png) |

## 💡 Important Considerations

- If the latest version of the SDK supports a privacy manifest, please upgrade as soon as possible to avoid unnecessary risks.
- This tool is a temporary solution and should not replace proper SDK management practices.
- Before submitting your app for review, ensure that the privacy manifest fix complies with the latest App Store requirements.

## 🙌 Contributing

Contributions in any form are welcome, including code optimizations, bug fixes, documentation improvements, and more. Please follow the project's guidelines and maintain a consistent coding style. Thank you for your support!
