# App Privacy Manifest Fixer

[![Latest Version](https://img.shields.io/github/v/release/crasowas/app_privacy_manifest_fixer?logo=github)](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)
![Supported Platforms](https://img.shields.io/badge/Supported%20Platforms-iOS%20%7C%20macOS-brightgreen)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**[English](./README.md) | 简体中文**

本工具是一个基于 Shell 脚本的自动化解决方案，旨在分析和修复 iOS/macOS App 的隐私清单，确保 App 符合 App Store 的要求。它利用 [App Store Privacy Manifest Analyzer](https://github.com/crasowas/app_store_required_privacy_manifest_analyser) 对 App 及其依赖项进行 API 使用分析，并生成或修复`PrivacyInfo.xcprivacy`文件。

## ✨ 功能特点

- **非侵入式集成**：无需修改源码或调整项目结构。
- **极速安装与卸载**：一行命令即可快速完成工具的安装或卸载。
- **自动分析与修复**：项目构建时自动分析 API 使用情况并修复隐私清单问题。
- **灵活定制模板**：支持自定义 App 和 Framework 的隐私清单模板，满足多种使用场景。
- **隐私访问报告**：自动生成报告用于查看 App 和 SDK 的`NSPrivacyAccessedAPITypes`声明情况。
- **版本轻松升级**：提供升级脚本快速更新至最新版本。

## 📥 安装

### 下载工具

1. 下载[最新发布版本](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)（推荐下载`.tar.gz`压缩包，可保留脚本的可执行权限）。
2. 解压下载的文件：
   - 解压后的目录通常为`app_privacy_manifest_fixer-xxx`（其中`xxx`是版本号）。
   - 建议重命名为`app_privacy_manifest_fixer`，或在后续路径中使用完整目录名。
   - **建议将该目录移动至 iOS/macOS 项目中，以避免因路径问题在不同设备上运行时出现错误，同时便于为每个项目单独自定义隐私清单模板**。

**新功能**：从`v1.5.0`版本开始，工具支持独立执行，无需依赖 Xcode。下载完成后可直接使用，无需安装。详细用法请参考[独立模式](#独立模式)。

### ⚡ 自动安装（推荐）

1. **切换到工具所在目录**：

   ```shell
   cd /path/to/app_privacy_manifest_fixer
   ```

2. **运行安装脚本**：

   ```shell
   ./install.sh <project_path>
   ```  
   
   - 如果是 Flutter 项目，`project_path`应为 Flutter 项目中的`ios/macos`目录路径。
   - 重复运行安装命令时，工具会先移除现有安装（如果有）。若需修改命令行选项，只需重新运行安装命令，无需先卸载。

### 手动安装

如果不使用安装脚本，可以手动添加`Fix Privacy Manifest`任务到 Xcode 的 **Build Phases** 完成安装。安装步骤如下：

#### 1. 在 Xcode 中添加脚本

- 用 Xcode 打开你的 iOS/macOS 项目，进入 **TARGETS** 选项卡，选择你的 App 目标。
- 进入 **Build Phases**，点击 **+** 按钮，选择 **New Run Script Phase**。
- 将新建的 **Run Script** 重命名为`Fix Privacy Manifest`。
- 在 Shell 脚本框中添加以下代码：

  ```shell
  # 使用相对路径（推荐）：如果`app_privacy_manifest_fixer`在项目目录内
  "$PROJECT_DIR/path/to/app_privacy_manifest_fixer/fixer.sh"

  # 使用绝对路径：如果`app_privacy_manifest_fixer`不在项目目录内
  # "/absolute/path/to/app_privacy_manifest_fixer/fixer.sh"
  ```

  **请根据实际情况修改`path/to`或`absolute/path/to`，并确保路径正确。同时，删除或注释掉不适用的行**。

#### 2. 调整脚本执行顺序

**将该脚本移动到所有其他 Build Phases 之后，确保隐私清单在所有资源拷贝和编译任务完成后再进行修复**。

### Build Phases 截图

下面是自动/手动安装成功后的 Xcode Build Phases 配置截图（未启用任何命令行选项）：

![Build Phases Screenshot](https://img.crasowas.dev/app_privacy_manifest_fixer/20250225011407.png)

## 🚀 快速开始

### 集成模式

安装后，工具将在每次构建项目时自动运行，构建完成后得到的 App 包已经是修复后的结果。

如果在安装时启用`--install-builds-only`命令行选项，工具将仅在安装构建时运行。

### 独立模式

无需安装，直接运行以下命令即可开始修复：

```shell
./fixer_wrapper.sh <path> [options]
```

- `<path>`：App 包路径，支持`.app`、`.ipa`和`.xcarchive`格式。
- `[options]`：详见[命令行选项](#命令行选项)。

**注意：**
- 修复改动将直接应用于原文件，并自动创建备份。
- 如果待修复的 App 包已签名，且本地存在匹配的签名证书，工具将自动完成重新签名。否则，可能需要你手动完成签名操作。

### Xcode Build Log 截图

下面是项目构建时工具输出的日志截图（默认会存储到`app_privacy_manifest_fixer/Build`目录，除非启用`-s`命令行选项）：

![Xcode Build Log Screenshot](https://img.crasowas.dev/app_privacy_manifest_fixer/20250225011551.png)

## 📖 使用方法

### 命令行选项

- **强制覆盖现有隐私清单（不推荐）**：

  ```shell
  # 集成模式
  ./install.sh <project_path> -f
  
  # 独立模式
  ./fixer_wrapper.sh <path> -f
  ```

  启用`-f`选项后，工具会根据 API 使用分析结果和隐私清单模板生成新的隐私清单，并强制覆盖现有隐私清单。默认情况下（未启用`-f`），工具仅修复缺失的隐私清单。

- **静默模式**：

  ```shell
  # 集成模式
  ./install.sh <project_path> -s
  
  # 独立模式
  ./fixer_wrapper.sh <path> -s
  ```

  启用`-s`选项后，工具将禁用修复时的输出，不再复制构建生成的`.app`、自动生成隐私访问报告或输出修复日志。默认情况下（未启用`-s`），这些输出存储在`app_privacy_manifest_fixer/Build`目录。

- **仅在安装构建时运行（推荐，仅用于集成模式）**：

  ```shell
  ./install.sh <project_path> --install-builds-only
  ```

  启用`--install-builds-only`选项后，工具仅在执行安装构建（如 **Archive** 操作）时运行，以优化日常开发时的构建性能。如果你是手动安装的，该命令行选项无效，需要手动勾选 **"For install builds only"** 选项。

  **注意**：如果 iOS/macOS 项目在开发环境构建（生成的 App 包含`.debug.dylib`文件），工具的 API 使用分析结果可能不准确。

### 升级工具

要更新至最新版本，请运行以下命令：

```shell
./upgrade.sh
```

### 卸载工具

要快速卸载本工具，请运行以下命令：

```shell
./uninstall.sh <project_path>
```

### 清理工具生成的文件

要删除工具生成的文件，请运行以下命令：

```shell
./clean.sh
```

## 🔥 隐私清单模板

隐私清单模板存储在[`Templates`](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates)目录，其中根目录已经包含默认模板。

**如何为 App 或 SDK 自定义隐私清单？只需使用[自定义模板](#自定义模板)！**

### 模板类型

模板分为以下几类：
- **AppTemplate.xcprivacy**：App 的隐私清单模板。
- **FrameworkTemplate.xcprivacy**：通用的 Framework 隐私清单模板。
- **FrameworkName.xcprivacy**：特定的 Framework 隐私清单模板，仅在`Templates/UserTemplates`目录有效。

### 模板优先级

对于 App，隐私清单模板的优先级如下：
- `Templates/UserTemplates/AppTemplate.xcprivacy` > `Templates/AppTemplate.xcprivacy`

对于特定的 Framework，隐私清单模板的优先级如下：
- `Templates/UserTemplates/FrameworkName.xcprivacy` > `Templates/UserTemplates/FrameworkTemplate.xcprivacy` > `Templates/FrameworkTemplate.xcprivacy`

### 默认模板

默认模板位于`Templates`根目录，目前包括以下模板：
- `Templates/AppTemplate.xcprivacy`
- `Templates/FrameworkTemplate.xcprivacy`

这些模板将根据 API 使用分析结果进行修改，特别是`NSPrivacyAccessedAPIType`条目将被调整，以生成新的隐私清单用于修复，确保符合 App Store 要求。

**如果需要调整隐私清单模板，例如以下场景，请避免直接修改默认模板，而是使用自定义模板。如果存在相同名称的自定义模板，它将优先于默认模板用于修复。**
- 由于 API 使用分析结果不准确，生成了不合规的隐私清单。
- 需要修改模板中声明的理由。
- 需要声明收集的数据。

`AppTemplate.xcprivacy`中隐私访问 API 类别及其对应声明的理由如下：

| [NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) | [NSPrivacyAccessedAPITypeReasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons) |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NSPrivacyAccessedAPICategoryFileTimestamp                                                                                                                          | C617.1: Inside app or group container                                                                                                                                            |
| NSPrivacyAccessedAPICategorySystemBootTime                                                                                                                         | 35F9.1: Measure time on-device                                                                                                                                                   |
| NSPrivacyAccessedAPICategoryDiskSpace                                                                                                                              | E174.1: Write or delete file on-device                                                                                                                                           |
| NSPrivacyAccessedAPICategoryActiveKeyboards                                                                                                                        | 54BD.1: Customize UI on-device                                                                                                                                                   |
| NSPrivacyAccessedAPICategoryUserDefaults                                                                                                                           | CA92.1: Access info from same app                                                                                                                                                |

`FrameworkTemplate.xcprivacy`中隐私访问 API 类别及其对应声明的理由如下：

| [NSPrivacyAccessedAPIType](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype) | [NSPrivacyAccessedAPITypeReasons](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitypereasons) |
|--------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| NSPrivacyAccessedAPICategoryFileTimestamp                                                                                                                          | 0A2A.1: 3rd-party SDK wrapper on-device                                                                                                                                          |
| NSPrivacyAccessedAPICategorySystemBootTime                                                                                                                         | 35F9.1: Measure time on-device                                                                                                                                                   |
| NSPrivacyAccessedAPICategoryDiskSpace                                                                                                                              | E174.1: Write or delete file on-device                                                                                                                                           |
| NSPrivacyAccessedAPICategoryActiveKeyboards                                                                                                                        | 54BD.1: Customize UI on-device                                                                                                                                                   |
| NSPrivacyAccessedAPICategoryUserDefaults                                                                                                                           | C56D.1: 3rd-party SDK wrapper on-device                                                                                                                                          |

### 自定义模板

要创建自定义模板，请将其放在`Templates/UserTemplates`目录，结构如下：
- `Templates/UserTemplates/AppTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkName.xcprivacy`

在这些模板中，只有`FrameworkTemplate.xcprivacy`会根据 API 使用分析结果对`NSPrivacyAccessedAPIType`条目进行调整，以生成新的隐私清单用于 Framework 修复。其他模板保持不变，将直接用于修复。

**重要说明：**
- 特定的 Framework 模板必须遵循命名规范`FrameworkName.xcprivacy`，其中`FrameworkName`需与 Framework 的名称匹配。例如`Flutter.framework`的模板应命名为`Flutter.xcprivacy`。
- 对于 macOS Framework，应遵循命名规范`FrameworkName.Version.xcprivacy`，额外增加版本名称用于区分不同的版本。对于单一版本的 macOS Framework，`Version`通常为`A`。
- SDK 的名称可能与 Framework 的名称不完全一致。要确定正确的 Framework 名称，请在构建项目后检查 App 包中的`Frameworks`目录。

## 📑 隐私访问报告

默认情况下，工具会自动在每次构建时为原始 App 和修复后的 App 生成隐私访问报告，并存储到`app_privacy_manifest_fixer/Build`目录。

如果需要手动为特定 App 生成隐私访问报告，请运行以下命令：

```shell
./Report/report.sh <app_path> <report_output_path>
```

- `<app_path>`：App 包路径（例如：/path/to/App.app）。
- `<report_output_path>`：报告文件保存路径（例如：/path/to/report.html）。

**注意**：工具生成的报告目前仅包含隐私访问部分（`NSPrivacyAccessedAPITypes`），如果想看数据收集部分（`NSPrivacyCollectedDataTypes`）请使用 Xcode 生成`PrivacyReport`。

### 报告示例截图

| 原始 App 报告（report-original.html）                                                                | 修复后 App 报告（report.html）                                                                     |
|------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| ![Original App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230746.png) | ![Fixed App Report](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230822.png) |

## 💡 重要考量 

- 如果最新版本的 SDK 支持隐私清单，请尽可能升级，以避免不必要的风险。
- 此工具仅为临时解决方案，不应替代正确的 SDK 管理实践。
- 在提交 App 审核之前，请检查隐私清单修复后是否符合最新的 App Store 要求。

## 🙌 贡献

欢迎任何形式的贡献，包括代码优化、Bug 修复、文档改进等。请确保遵循项目规范，并保持代码风格一致。感谢你的支持！
