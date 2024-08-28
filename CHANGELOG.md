# 2024-08-28 v6.8.2

#### Bugs Fixed

- Fix an issue where the SDK could fail to resume after the device is unlocked
- Improve button layout in Prompts with long button labels
- Mitigate possibility of a crash when uploading a photo or video to an Alchemer Survey
- Ensure links in Alchemer Surveys shown on mobile are opened in the system browser
- Allow Alchemer Surveys to follow device orientation
- Improve accessibility with Prompts and Surveys containing rich content images and text

# 2024-06-04 v6.8.1

#### Bugs Fixed

- The privacy manifest is now included in the resource bundle for CocoaPods integrations
- Fixed an issue where button labels could appear blank when increased contrast was enabled

# 2024-05-29 - v6.8.0

#### New Features

- Advanced Customer Research support to show Alchemer long-form surveys through prompts

# 2024-04-17 - v6.7.0

#### New Features

- Added rich text support through dashboard for Prompts and Surveys
 
#### Bugs Fixed

- Fixed a concurrency issue that could lead to a crash when an HTTP request is retried
- Fixed an issue where the background of a Prompt or Love Dialog remained responsive to taps in Flutter
- Restored the ability to set a Prompt or Love Dialog header image via UIAppearance

# 2024-03-25 - 6.6.0

#### New & Improved:

- Added image support through dashboard for Prompts (previously called Notes)

#### Bugs Fixed:

- Fixed some layout issues in paged Surveys
- Privacy manifest is now included in Package.swift

# 2023-10-31 - 6.5.0

#### New & Improved:

- Added a [Privacy Manifest](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files) to declare information on data collected by the SDK
- Incremented the deployment target to iOS 13.0

#### Bugs Fixed:

- Message Center now checks if it is already visible when opening in response to a push notification.
- The close confirmation alert is now shown if an "Other" choice has been selected in Surveys.
- Fixed a layout issue that sometimes appeared in Message Center.
- The compose field in Message Center now clears after a message is sent, even when an autocorrect suggestion is accepted.

# 2023-08-29 - 6.2.3

#### New & Improved:

- Enhancements and fixes to Message Center focused on accessibility and keyboard navigation
- Log category is now "Apptentive" rather than "PointsOfInterest"

#### Bugs Fixed:

- Logs now show without any redaction, even when not using a debugger

# 2023-07-06 - 6.2.2

#### New & Improved:

- Context messages in Message Center now have clickable URLs, emails, and phone numbers

#### Bugs Fixed:

- Fixed an issue that broke VoiceOver navigation in surveys when not using a full-screen modal presentation style
- Fixed an issue that could prevent engaging the (internal) launch event in SceneDelegate apps written in Objective-C

# 2023-05-18 - 6.2.1

#### New & Improved

- Added a new `apptentiveTint` property to the `UIColor` extension to set the default accent color for Apptentive interaction UI

#### Bugs Fixed

- Fixed an issue where the (internal) exit event was sent twice

#### New & Improved

- Implemented Customer Authentication features from the legacy SDK in the new SDK (See iOS Integration Reference - Apptentive Customer Learning Center )
- Added async versions of Apptentive methods with a completion handler argument
- Added a canShowMessageCenter() method
- Added an error when a event with an empty name is engaged
- Added the ability to work with multiple app key/signature pairs without deleting and reinstalling

#### Bugs Fixed

- Fixed button placement issues in Notes and the Love Dialog
- Improved handling of long “Terms and Conditions” text in Surveys
- Fixed a potential name collision between the ApptentiveKit framework and its resource bundle in CocoaPods, Flutter, React Native, and Cordova integrations

# 2023-02-07 - 6.1.0

### New & Improved

- Love Dialog and Notes interaction UI can now be customized

### Bugs Fixed

- The lower limit on selection count for checkbox questions is now enforced even when a response is not required
- The minimum and maximum labels for range and NPS questions will now hyphenate words to fit the available space with large Dynamic Type sizes

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
