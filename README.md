# App Privacy Manifest Fixer

This shell-based tool is built to analyze and update privacy manifests in iOS apps, ensuring compliance with App Store requirements.

**Privacy manifests should be managed by third-party SDK developers.** Whenever possible, prefer upgrading to the latest SDK versions. Use this tool only in the following cases:

* The SDK is deprecated and no longer maintained. 
* The latest SDK version is incompatible with your iOS project. 
* The SDK does not provide a privacy manifest.

## Features

* Automatically integrates into your iOS project.
* Analyzes API usage and automatically updates the privacy manifest during the build process.
* Customizable privacy manifest templates for your app, frameworks, or even a specific framework.
* Provides an upgrade script for the tool.

## Installation

### Download the Latest Version

1. Download the latest release from the [GitHub repository](https://github.com/crasowas/app_privacy_manifest_fixer/releases).
2. For better portability, we recommend extracting the downloaded archive and placing the folder in your iOS project directory.

### Add the Tool to Your Project

```shell
sh install.sh <project_path>
```

This will automatically add a `Fix Privacy Manifest` step to your project's build phases.

To forcefully overwrite the existing privacy manifest, use the `-f` option (not recommended). By default, the privacy manifest will not be updated if it already exists.

```shell
sh install.sh <project_path> -f
```

We recommend using the `--install-builds-only` option, which ensures that the `Fix Privacy Manifest` step is executed only during install builds (e.g., Archive operations), thus speeding up development builds.

```shell
sh install.sh <project_path> --install-builds-only
```

## Usage

Once installed, the tool runs automatically every time the project is built.

Update to the latest version by running:

```shell
sh upgrade.sh
```

## Templates

The privacy manifest templates are stored in the [Templates](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates) directory. Custom templates should be placed in the `UserTemplates` subdirectory, which has a higher priority.

Privacy manifest templates are divided into three types:

* **App.xcprivacy:** The privacy manifest template for the app.
* **Framework.xcprivacy:** A general privacy manifest template for frameworks.
* **FrameworkName.xcprivacy:** A specific privacy manifest template for a framework, available in the `UserTemplates` directory only.

You can create custom templates in the `UserTemplates` directory as follows:

* `Templates/UserTemplates/App.xcprivacy`
* `Templates/UserTemplates/Framework.xcprivacy`
* `Templates/UserTemplates/FrameworkName.xcprivacy`

Among these, `Framework.xcprivacy` will be modified based on API usage analysis results to fix the privacy manifest.

**Note:** Name each template using the format `FrameworkName.xcprivacy`, where `FrameworkName` is the name of the specific framework. For example, the template for the `Flutter` framework should be named `Flutter.xcprivacy`. 
The SDK name may not always match the Framework name. If unsure, check the Application Bundle after building to identify the correct Framework name associated with the SDK.
