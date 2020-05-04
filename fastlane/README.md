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
### ios integration_test_production
```
fastlane ios integration_test_production
```
Run integration tests against production
### ios integration_test_staging
```
fastlane ios integration_test_staging
```
Run integration tests against staging
### ios integration_test_dev
```
fastlane ios integration_test_dev
```
Run integration tests against dev
### ios integration_test_local
```
fastlane ios integration_test_local
```
Run integration tests against localhost
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
### ios framework
```
fastlane ios framework
```
Builds Apptentive xcframework binary
### ios zipArtifacts
```
fastlane ios zipArtifacts
```
Zips all xcarchive and xcframework
### ios beta
```
fastlane ios beta
```
Deploys Operator app to TestFlight

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
