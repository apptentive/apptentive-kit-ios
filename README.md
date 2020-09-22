# Apple-SDK

Apptentive apple sdk

# CI / CD

* [Travis](https://travis-ci.com/github/apptentive/apple-sdk)
* [Github Releases](https://github.com/apptentive/apple-sdk/releases)

Release Names: `iOSBundleShortVersion-GitBranch+TravisBuildNumber`

## Running Integration Tests Locally

The integration tests included in the SDK need Apptentive credentials to run. These are looked up using the `UserDefaults` system. The recommended way of setting these up is to rename the `Defaults-Template.plist` file to `Defaults.plist` and enter them there. They can also be set via command line arguments to the test bundle. 

## `swift-format` Version

The `lint`, `lint-all`, and `format` Fastlane lanes require the `swift-format` binary to be installed. You can build it from source (https://github.com/apple/swift-format) or install it from [Homebrew](https://brew.sh), but you will need the Swift 5.3 branch for linting to work correctly. 

We maintain a [tap](https://github.com/apptentive/homebrew-travis) with our customized `swift-format-5.3` formula, which incorporates fixes that the mainline `swift-format` formula lacks (as of 2020-09-18): 

```
$ brew tap apptentive/travis
$ brew install swift-format-5.3
```

You may have to update the SHA of the head of that branch. 
