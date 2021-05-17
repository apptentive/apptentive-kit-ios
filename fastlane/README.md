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
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios test
```
fastlane ios test
```
Run tests
### ios coverage
```
fastlane ios coverage
```
Generates a code coverage report
### ios lint
```
fastlane ios lint
```
Runs the swift-format linter on ApptentiveKit
### ios lint_all
```
fastlane ios lint_all
```
Runs the swift-format linter on all swift files in repo
### ios format
```
fastlane ios format
```
Runs the swift-format formatter in-place on all swift files
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
