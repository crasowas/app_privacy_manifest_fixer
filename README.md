# App Privacy Manifest Fixer

This shell-based tool is built to analyze and update privacy manifests in iOS apps, ensuring compliance with App Store requirements.

> **Note:** Privacy manifests should ideally be maintained by third-party SDK developers.  
> Use this tool only in the following cases:
> 1. The SDK has been deprecated and is no longer maintained.
> 2. The latest SDK version is incompatible with your iOS project.
> 3. The SDK does not provide a privacy manifest.

## Features

- **Seamless Integration**: Easily integrates or uninstalls from your iOS project.
- **Automated Analysis**: Analyzes API usage and updates privacy manifests during the build process.
- **Custom Templates**: Supports customizable privacy manifest templates for apps, generic frameworks, and specific frameworks.
- **Easy Upgrades**: Includes a script to easily upgrade the tool to the latest version.

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

To update to the latest version, execute:

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

### Create Custom Templates

To create custom templates, place them in the `UserTemplates` directory with the following structure:

- `Templates/UserTemplates/AppTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkName.xcprivacy`

Among these, only `FrameworkTemplate.xcprivacy` will be modified based on API usage analysis results to produce a new privacy manifest, while other templates will remain unchanged.

**Important Notes:**

- Specific framework templates must follow the naming convention `FrameworkName.xcprivacy`, where `FrameworkName` matches the framework's name. For example, the `Flutter` framework template should be named `Flutter.xcprivacy`.
- The SDK name may not always match the framework name. To identify the correct framework name, check the Application Bundle after building your project.

## Important Considerations

- Whenever possible, upgrade to the latest SDK version that supports privacy manifests to avoid unnecessary risks.
- This tool is a temporary solution and should not replace proper SDK management practices.
- Before submitting your app, ensure that the privacy manifests comply with the latest App Store requirements.
