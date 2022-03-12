# 2022-03-08 - 6.0.0

#### Improvements

- Add Message Center

#### API Changes

- The `register(credentials:completion:)` method has been renamed to `register(with:completion:)`
- The `register(with:completion:)` method's completion handler parameter has changed from a `Result<Bool, Error>` to a `Result<Void, Error>`

#### Known Issues and Limitations

- Push notification support is not yet implemented
- Custom data passed via the `engage(event:from:completion:)` method is not yet implemented
- The `dismissAllInteractions()` method is not yet implemented
- The `logIn(token:completion:)` and `logOut()` methods are not yet implemented

# 2021-11-18 - 6.0.0-beta.4

#### Bug Fixes

- Fix a bug that caused conversation size to grow exponentially
- Fix a bug that could cause interactions to be counted twice for targeting purposes
- Fix a bug that could cause requests to not be retried properly
- Fix a bug that could cause survey responses to not send correctly

# 2021-10-04 - 6.0.0-beta.3

#### Bug Fixes

- Fix a memory leak when presenting interactions
- Fix the delay calculation for retrying failed network requests
- Fix warnings due to setting translatesAutoresizingMaskIntoConstraints for table view cells
- Fix spelling of apptentiveTextInput extension property on UIFont
- Fix a bug where retried request could become stuck in the event of a particular class of network error
- Work around an iOS 15 bug that led to clear navigation and tool bars

#### Improvements

- Add a toggle to disable the toolbar in Surveys
- Make the Payload Sender module use a background task to finish sending payloads on app exit
- Add ability to set an image for the survey navigation bar's title view
- Add documentation comments to remaining public methods and properties

# 2021-09-01 - 6.0.0-beta.2

#### Improvements

- Add support for iOS 11 deployment targets

# 2021-08-31 - 6.0.0-beta.1

Initial beta release of Apptentive's Swift SDK for iOS
