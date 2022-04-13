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