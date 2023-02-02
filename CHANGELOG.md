# 2023-02-02 - 6.0.9

### Bugs Fixed

- Fixed an issue where the completion handler passed to `register(with:completion:)` could be called twice, resulting in an error in React Native apps.

# 2022-12-13 - 6.0.8

### New & Improved

- Add support for Malay, Thai, and Indonesian localizations
- A dark mode update across interactions for our out of box theme 

### Bugs Fixed

- Fixed an issue causing some react native builds to fail

# 2022-11-09 - 6.0.7

#### New & Improved

- Added finer-grained customization options for Message Center

#### Bugs Fixed

- Fixed the data migration from version 5 or earlier of the SDK to version 6.0.5 or 6.0.6

# 2022-10-20 - 6.0.6

*Note:* v6.0.5 contains a bug that only affects those using CocoaPods or a framework that uses CocoaPods internally (React Native, Flutter, and mParticle). There is no need for those not affected to update from v6.0.5 to v6.0.6. 

#### Bugs Fixed

- Added a missing file to the resource bundle for CocoaPods integrations that was causing an assertion failure.

# 2022-10-17 - 6.0.5

#### New & Improved

- Removed the status label from the Edit Profile view in Message Center

#### Bugs Fixed

- Fixed an issue where encountering an assertion failure in a release build causes a crash
- Fixed an issue where calling register before protected data is available could cause an error
- Fixed an issue where the SDK version could be reported incorrectly
- Fixed a spurious error message on first app launch

# 2022-09-01 - 6.0.4

#### New & Improved

- Improved VoiceOver navigation in Surveys
- Fixed some issues with large Dynamic Type sizes in Surveys
- Improved contrast ratios in Surveys and Message Center
- Enabled URLs, email addresses, dates, and physical addresses to be opened in Message Center
- Range questions in surveys now use localized numerals
- Added `apptentiveAssertionHandler` to allow changing behavior in case of a critical error (e.g. during testing)

#### Bugs Fixed

- Fixed an issue with selection and deselection of choice questions in Surveys
- Fixed an issue where the Message Center configuration could fail to decode due to missing required fields

# 2022-06-16 - 6.0.3

#### New & Improved

- Added additional customization properties:
  - `CGFloat.apptentiveButtonBorderWidth`
  - `UIColor.apptentiveSubmitButtonBorder`
- Renamed the `UIColor` and `UIFont` extension properties from `apptentiveSubmitLabel` to `apptentiveSubmitStatusLabel` (the old name is still present but deprecated)
- Marked the `key` and `signature` properties on `Apptentive.AppCredentials` as `public` (to facilitate testing code that creates a credentials object)
- Added `@objc` annotations to interaction UI customization parameters
- Added appropriate guards to allow the SDK to compile for Mac Catalyst targets*

*We recommend that your code avoid any calls to ApptentiveKit methods when running in a Mac Catalyst app, since some interactions are not currently usable in a desktop environment. 

#### Bugs Fixed

- Fixed a layout issue in Message Center
- Corrected Objective-C method signatures for better backward compatibility with previous iOS SDK versions
- Fixed an issue with using non-integer parameters in targeting criteria
- Fixed a bug where a branding setting could cause a Message Center interaction to fail to decode
- Adjusted the text size in range controls to allow them to display properly on smaller devices
- Fixed an issue where setting a value for `Apptentive.interactionPresenter` did not set its (internal) `interactionDelegate` property

# 2022-05-05 - 6.0.2

#### New & Improved

- Increased the contrast between the numbers and background for NPS/range inputs in Surveys
- Increased the available space the “Thank You” message in Surveys
- Increased the reliability of parsing interaction configurations

#### Bugs fixed

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
