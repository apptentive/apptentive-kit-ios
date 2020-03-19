fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## iOS
### ios unit_test
```
fastlane ios unit_test
```
Run unit tests (standalone)
### ios ui_test
```
fastlane ios ui_test
```
Run UI tests (standalone)
### ios zipArtifacts
```
fastlane ios zipArtifacts
```
Zips all xcarchive and xcframework
### ios framework_production
```
fastlane ios framework_production
```
Builds Apptentive xcframework binary pointed at production servers
### ios framework_staging
```
fastlane ios framework_staging
```
Builds Apptentive xcframework binary pointed at staging servers
### ios framework_dev
```
fastlane ios framework_dev
```
Builds Apptentive xcframework binary pointed at dev servers
### ios framework_local
```
fastlane ios framework_local
```
Builds Apptentive xcframework binary pointed at localhost

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
