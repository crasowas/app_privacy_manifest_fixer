## 1.4.0
- Support for macOS app ([#9](https://github.com/crasowas/app_privacy_manifest_fixer/issues/9)).

## 1.3.11
- Fix install issue by skipping `PBXAggregateTarget` ([#4](https://github.com/crasowas/app_privacy_manifest_fixer/issues/4)).

## 1.3.10
- Fix app re-signing issue.
- Enhance Build Phases script robustness.

## 1.3.9
- Add log file output.

## 1.3.8
- Add version info to privacy access report.
- Remove empty tables from privacy access report.

## 1.3.7
- Enhance API symbols analysis with strings tool.
- Improve performance of API usage analysis.

## 1.3.5
- Fix issue with inaccurate privacy manifest search.
- Disable dependency analysis to force the script to run on every build.
- Add placeholder for privacy access report.
- Update build output directory naming convention.
- Add examples for privacy access report.

## 1.3.0
- Add privacy access report generation.

## 1.2.3
- Fix issue with relative path parameter.
- Add support for all application targets.

## 1.2.1
- Fix backup issue with empty user templates directory.

## 1.2.0
- Add uninstall script.

## 1.1.2
- Remove `Templates/.gitignore` to track `UserTemplates`.
- Fix incorrect use of `App.xcprivacy` template in `App.framework`.

## 1.1.0
- Add logs for latest release fetch failure.
- Fix issue with converting published time to local time.
- Disable showing environment variables in the build log.
- Add `--install-builds-only` command line option.

## 1.0.0
- Initial version.