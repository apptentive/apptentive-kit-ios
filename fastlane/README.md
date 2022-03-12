fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios clean

```sh
[bundle exec] fastlane ios clean
```

Clean build areas

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

### ios coverage

```sh
[bundle exec] fastlane ios coverage
```

Generates a code coverage report

### ios lint

```sh
[bundle exec] fastlane ios lint
```

Runs the swift-format linter on ApptentiveKit

### ios lint_all

```sh
[bundle exec] fastlane ios lint_all
```

Runs the swift-format linter on all swift files in repo

### ios format

```sh
[bundle exec] fastlane ios format
```

Runs the swift-format formatter in-place on all swift files

### ios framework

```sh
[bundle exec] fastlane ios framework
```

Builds Apptentive xcframework binary

### ios zipArtifacts

```sh
[bundle exec] fastlane ios zipArtifacts
```

Zips all xcarchive and xcframework

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Gets development certs

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Deploys Operator app to TestFlight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
