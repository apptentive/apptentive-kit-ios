# 2022-05-04 - 6.0.2

#### New & Improved

- Increased the contrast between the numbers and background for NPS/range inputs in Surveys
- Increased the available space the “Thank You” message in Surveys
- Increased the reliability of parsing interaction configurations

#### Bugs Fixed

- Fixed the layout of extremely long messages/conversations in Message Center

# 2022-04-13 - 6.0.1

#### New & Improved

- Automated messages available in Message Center
- New method available to dismiss all interactions 
- Allow custom data to be passed with events
- Send a notification (`apptentiveEventEngaged`) when an event is engaged
- Increased the contrast for survey buttons
- Added method to determine whether an event may trigger an interaction

#### Bug Fixes & User Experience Updates

- Fixed an issue with localized strings when integrating with Swift Package Manager
- Fixed an issue where API requests were sent on every keystroke
- Fixed an issue with CocoaPods integrations on iOS 11
- Fixed a potential crash when setting custom person or device data
- Fixed a crash when closing a partially-completed survey on iPad
- Fixed a potential crash when using a swipe gesture to dismiss a partially-completed survey
- Fixed a layout issue in Message Center when profile view is visible 
- Other miscellaneous user experience improvements

# 2022-03-17 - 6.0.0

Initial release of the ApptentiveKit SDK for iOS and iPadOS

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

# Previous Releases

You can find versions 5 and earlier in our [legacy SDK repository](https://github.com/apptentive/apptentive-ios). 

For a limited time, you can find beta relases of version 6 in our [beta repository](https://github.com/apptentive/apptentive-ios-sdk).