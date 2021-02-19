# Apple-SDK

Apptentive SDK for Apple platforms. Currently intended to support UIKit-based apps running on iOS. 

# CI / CD

* [Travis](https://travis-ci.com/github/apptentive/apple-sdk)
* [Github Releases](https://github.com/apptentive/apple-sdk/releases)

Release Names: `iOSBundleShortVersion-GitBranch+TravisBuildNumber`

## Running Integration Tests Locally

The integration tests included in the SDK need Apptentive credentials to run. These are looked up using the `UserDefaults` system. The recommended way of setting these up is to rename the `Defaults-Template.plist` file to `Defaults.plist` and enter them there. They can also be set via command line arguments to the test bundle. 
