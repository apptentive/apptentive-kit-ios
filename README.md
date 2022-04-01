# ApptentiveKit

ApptentiveKit lets you integrate your iPhone and iPad apps with Apptentive's customer communications platform. 

Use Apptentive features to improve your app's App Store ratings, collect and respond to customer feedback, show surveys at specific points within your app, and more.

## Adding the ApptentiveKit Dependency

We recommend using Swift Package Manager to include ApptentiveKit in your project. 

In Xcode, choose File > Add Packages… and add the URL for this repository.

**NOTE: CocoaPods users targeting iOS 11 should refer to the [release notes](https://learn.apptentive.com/knowledge-base/apptentive-kit-ios-release-notes/#known-issues) for a workaround to an issue in version 6.0.0.** 

## Using ApptentiveKit in Your App

To use Apptentive features in your Swift files, you will have to import the ApptentiveKit module:

```Swift
import ApptentiveKit
```

Early in your app's lifecycle, call the `register(with:completion:)` method on the shared `Apptentive` instance:

```Swift
Apptentive.shared.register(with: .init(key: "<#Your Apptentive App Key#>", signature: "<#Your Apptentive App Signature#>"))
```

At various points in your app, use the `engage(event:from:completion:)` method to record events with ApptentiveKit. When an event is engaged, the SDK can be configured to display an interaction, such as a Note, Survey, or Love Dialog, and you can define segments based on which events were engaged on your customer's device. 

```Swift
@IBAction func completePurchase(sender: UIButton) {
    // ...
    
    Apptentive.shared.engage("purchase_complete", from: self) // where `self` is a UIViewController instance.
}
```

If you plan to use Message Center, you should have a button in your app where your customers can open Message Center:

```Swift
@IBAction func openMessageCenter(sender: UIButton) {
    // ...
    
    Apptentive.shared.presentMessageCenter(from: self) // where `self` is a UIViewController instance.
}
```

## Further Reading

Please visit our [Customer Learning Center](https://learn.apptentive.com) for more extensive integration and migration guides, as well as guides for product owners and developers for other platforms. 

## Contributing

Our client code is completely [open source](LICENSE.txt), and we welcome contributions to the Apptentive SDK! If you have an improvement or bug fix, please first read our [contribution agreement](CONTRIBUTING.md).

## Reporting Issues

If you experience an issue with the Apptentive SDK, please [open a GitHub issue](https://github.com/apptentive/apptentive-ios/issues?direction=desc&sort=created&state=open).

If the request is urgent, please contact <mailto:support@apptentive.com>.