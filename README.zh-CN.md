# App Privacy Manifest Fixer

[![Latest Version](https://img.shields.io/github/v/release/crasowas/app_privacy_manifest_fixer?logo=github)](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

**[English](./README.md) | 简体中文**

本修复工具基于Shell脚本，用于分析和修复iOS App的隐私清单，以确保符合App Store的要求。其中API使用分析功能基于[app_store_required_privacy_manifest_analyser](https://github.com/crasowas/app_store_required_privacy_manifest_analyser)实现。

> **注意：** 理想情况下隐私清单应由第三方SDK开发者维护。  
> 主要在以下情况下使用此修复工具：
> 1. SDK已被弃用且不再进行维护。
> 2. 最新版本的SDK和现有的iOS项目不兼容。
> 3. SDK未提供隐私清单。
> 4. 不是独立SDK，而是作为构建过程的一部分生成的Framework，例如`Flutter`项目中的`App.framework`。
> 5. SDK的依赖项存在上述问题，且无法通过升级主SDK解决。

## 功能特点

- **无缝集成**：安装/卸载修复工具都只需要一行命令。
- **自动分析**：构建过程中自动分析API使用并修复隐私清单。
- **隐私访问报告**：自动生成报告用于查看App和SDK的隐私访问详情，以及用于修复的隐私清单模板。
- **自定义模板**：支持自定义App、通用Framework以及特定Framework的隐私清单模板。
- **便捷升级**：提供升级脚本，快速更新到最新版本。

## 安装指南

### 下载最新版本

1. **下载[最新发布版本](https://github.com/crasowas/app_privacy_manifest_fixer/releases/latest)。**
2. **解压下载的文件**。建议将解压后的目录放到iOS项目中，一是避免运行在不同设备上出现路径问题，二是方便为每个项目单独自定义隐私清单模板。

### 安装工具

运行以下命令将修复工具安装到项目中：

```shell
sh install.sh <project_path>
```

如果重复运行该命令，现有的安装将被自动覆盖。如果需要变更命令行选项，直接重新运行该命令，无需先卸载。

#### 命令行选项

- **强制覆盖已有隐私清单（不推荐）**：启用`-f`选项，修复工具会根据API使用分析结果以及隐私清单模板生成新的隐私清单，用于替换已存在的。默认情况下（未启用 `-f`），修复工具仅修复缺失的隐私清单。

  ```shell
  sh install.sh <project_path> -f
  ```

- **静默模式**：启用`-s`选项可禁用构建输出，不再复制构建生成的App以及自动生成隐私访问报告（这些输出仅用于观察修复前后情况，不影响实际修复）。默认情况下（未启用`-s`），修复工具会自动生成修复前后的隐私访问报告并存储在`app_privacy_manifest_fixer/Build`目录下。

  ```shell
  sh install.sh <project_path> -s
  ```

- **仅在安装构建时运行（推荐）**：启用`--install-builds-only`选项可使修复工具仅在安装构建（如 `Archive` 操作）时运行，从而优化开发构建时的性能。

  ```shell
  sh install.sh <project_path> --install-builds-only
  ```

  **注意：若App在开发调试环境构建（构建产物包含 `*.debug.dylib` 文件），修复工具的API使用分析结果可能会不准确。**

### 卸载工具

运行以下命令卸载修复工具：

```shell
sh uninstall.sh <project_path>
```

## 使用方式

安装后，修复工具将在每次构建项目时自动运行，构建完成后得到的应用程序包已经是修复后的结果。

如果使用 `--install-builds-only` 选项安装，修复工具将仅在安装构建时运行。

### 升级工具

要更新至最新版本，请运行以下命令：

```shell
sh upgrade.sh
```

## 隐私访问报告

默认情况下，修复工具会在每次构建时为原始应用和修复后的应用生成隐私访问报告（启用静默模式时不会生成），并存储在`app_privacy_manifest_fixer/Build`目录下。

### 报告示例

| 原始应用报告                                                                            | 修复后应用报告                                                                            |
|-----------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| ![原始应用报告](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230746.png) | ![修复后应用报告](https://img.crasowas.dev/app_privacy_manifest_fixer/20241218230822.png) |

### 手动生成报告

如果需要手动为特定App生成隐私访问报告，请运行以下命令：

```shell
sh Report/report.sh <app_path> <report_output_path>
# <app_path>: App路径（例如：/path/to/App.app）
# <report_output_path>: 报告文件保存路径（例如：/path/to/report.html）
```

## 隐私清单模板

隐私清单模板存储在 [`Templates`](https://github.com/crasowas/app_privacy_manifest_fixer/tree/main/Templates) 目录中，其中已包含默认模板。

**如何为App或SDK自定义隐私清单？只需使用[自定义模板](#自定义模板)！**

### 模板类型

模板分为以下几类：

- **AppTemplate.xcprivacy**：App的隐私清单模板。
- **FrameworkTemplate.xcprivacy**：通用的Framework隐私清单模板。
- **FrameworkName.xcprivacy**：特定的Framework隐私清单模板，仅在`UserTemplates`目录中有效。

### 模板优先级

对于App，隐私清单模板的优先级如下：

- `Templates/UserTemplates/AppTemplate.xcprivacy` > `Templates/AppTemplate.xcprivacy`

对于特定的Framework，隐私清单模板的优先级如下：

- `Templates/UserTemplates/FrameworkName.xcprivacy` > `Templates/UserTemplates/FrameworkTemplate.xcprivacy` > `Templates/FrameworkTemplate.xcprivacy`

### 默认模板

默认模板位于 `Templates` 根目录中，目前包括以下模板：

- `Templates/AppTemplate.xcprivacy`
- `Templates/FrameworkTemplate.xcprivacy`

这些模板将根据API使用分析结果进行修改，特别是`NSPrivacyAccessedAPIType`条目将被调整，以生成新的隐私清单，确保符合要求。

**如果需要调整隐私清单模板，例如以下场景，请避免直接修改默认模板，而是使用自定义模板。如果存在相同名称的自定义模板，它将优先于默认模板。**

- 由于API使用分析结果不准确，生成了不合规的隐私清单。
- 需要修改模板中声明的理由。
- 添加收集数据的声明。

`AppTemplate.xcprivacy`中的API分类及其对应的声明理由如下：

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons        |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | C617.1: Inside app or group container  |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device         |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device         |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | CA92.1: Access info from same app      |

`FrameworkTemplate.xcprivacy`中的API分类及其对应的声明理由如下：

| NSPrivacyAccessedAPIType                                                                                                                                            | NSPrivacyAccessedAPITypeReasons         |
|---------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| [NSPrivacyAccessedAPICategoryFileTimestamp](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#File-timestamp-APIs)    | 0A2A.1: 3rd-party SDK wrapper on-device |
| [NSPrivacyAccessedAPICategorySystemBootTime](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#System-boot-time-APIs) | 35F9.1: Measure time on-device          |
| [NSPrivacyAccessedAPICategoryDiskSpace](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Disk-space-APIs)            | E174.1: Write or delete file on-device  |
| [NSPrivacyAccessedAPICategoryActiveKeyboards](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#Active-keyboard-APIs) | 54BD.1: Customize UI on-device          |
| [NSPrivacyAccessedAPICategoryUserDefaults](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api#User-defaults-APIs)      | C56D.1: 3rd-party SDK wrapper on-device |

### 自定义模板

要创建自定义模板，请将其放置在`UserTemplates`目录中，结构如下：

- `Templates/UserTemplates/AppTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkTemplate.xcprivacy`
- `Templates/UserTemplates/FrameworkName.xcprivacy`

在这些模板中，只有`FrameworkTemplate.xcprivacy`会根据API使用分析结果进行调整`NSPrivacyAccessedAPIType`条目，以生成新的隐私清单用于Framework修复。其他模板保持不变，将直接用于修复。

**重要说明：**

- 特定的Framework模板必须遵循命名规范`FrameworkName.xcprivacy`，其中`FrameworkName`需与Framework的名称匹配。例如`Flutter` Framework的模板应命名为`Flutter.xcprivacy`。
- SDK的名称可能与Framework的名称不完全一致。要确定正确的Framework名称，请在构建项目后检查应用程序包中的内容。

## 重要考量

- 只要有可能，请升级至支持隐私清单的最新SDK版本，以避免不必要的风险。
- 此修复工具仅为临时解决方案，不应替代正确的SDK管理实践。
- 在提交应用之前，请确保隐私清单符合最新的App Store要求。
