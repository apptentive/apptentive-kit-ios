//
//  Apptentive+Compatibility.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

// swift-format-ignore-file

// We don't necessarily want to expose doc comments for this stuff. Doc comments that exist come
// from generated Swift output of the original Objective-C.

import UIKit

extension Apptentive {
    @available(*, deprecated, message: "Use the `register` method on the `shared` instance instead.")
    @objc(registerWithConfiguration:) public class func register(with configuration: ApptentiveConfiguration) {
        ApptentiveLogger.logLevel = configuration.logLevel.logLevel

        if let distributionName = configuration.distributionName {
            self.shared.environment.distributionName = distributionName
        }

        if let distributionVersion = configuration.distributionVersion {
            self.shared.environment.distributionVersion = Version(string: distributionVersion)
        }

        self.shared.register(credentials: AppCredentials(key: configuration.apptentiveKey, signature: configuration.apptentiveSignature))
    }

    @available(*, deprecated, message: "Use the `shared` static property instead.")
    @objc public class func sharedConnection() -> Apptentive {
        return Apptentive.shared
    }

    @available(*, deprecated, message: "This property is ignored. An `SKStoreReviewController` will be used for all ratings.")
    @objc public var appID: String? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "This property is ignored. The info button no longer exists.")
    @objc public var showInfoButton: Bool {
        get {
            false
        }
        set {}
    }

    @available(*, deprecated, message: "This feature is not implemented.")
    @objc public var surveyTermsAndConditions: TermsAndConditions? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "This property is not available for reading.")
    @objc public var apptentiveKey: String {
        ""
    }

    @available(*, deprecated, message: "This property is not available for reading.")
    @objc public var apptentiveSignature: String {
        ""
    }

    @objc(engage:fromViewController:) public func engage(_ event: String, fromViewController viewController: UIViewController?) {
        self.engage(event: Event(name: event), from: viewController)
    }

    @objc(engage:fromViewController:completion:) public func engage(_ event: String, fromViewController viewController: UIViewController?, completion: ((Bool) -> Void)? = nil) {
        self.engage(event: Event(name: event), from: viewController) { (result) in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @available(*, deprecated, message: "Event custom data are no longer supported. Event will be engaged without custom data.")
    @objc(engage:withCustomData:fromViewController:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, from viewController: UIViewController?) {
        ApptentiveLogger.engagement.error("Event custom data are no longer supported. Event will be engaged without custom data.")
        self.engage(event: Event(name: event), from: viewController, completion: nil)
    }

    @available(*, deprecated, message: "Event custom data are no longer supported. Event will be engaged without custom data.")
    @objc(engage:withCustomData:fromViewController:completion:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, from viewController: UIViewController?, completion: ((Bool) -> Void)? = nil) {
        ApptentiveLogger.engagement.error("Event custom data are no longer supported. Event will be engaged without custom data.")
        self.engage(event: Event(name: event), from: viewController) { (result) in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @available(*, deprecated, message: "Event custom and extended data are no longer supported. Event will be engaged without custom or extended data.")
    @objc(engage:withCustomData:withExtendedData:fromViewController:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, withExtendedData extendedData: [[AnyHashable: Any]]?, from viewController: UIViewController?) {
        ApptentiveLogger.engagement.error("Event custom and extended data are no longer supported. Event will be engaged without custom or extended data.")
        self.engage(event: Event(name: event), from: viewController, completion: nil)
    }

    @available(*, deprecated, message: "Event custom and extended data are no longer supported. Event will be engaged without custom or extended data.")
    @objc(engage:withCustomData:withExtendedData:fromViewController:completion:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, withExtendedData extendedData: [[AnyHashable: Any]]?, from viewController: UIViewController?, completion: ((Bool) -> Void)? = nil) {
        ApptentiveLogger.engagement.error("Event custom and extended data are no longer supported. Event will be engaged without custom or extended data.")
        self.engage(event: Event(name: event), from: viewController) { (result) in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @available(*, deprecated, message: "This feature is not implemented and will always result in false.")
    @objc public func queryCanShowInteraction(forEvent event: String, completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    @available(*, deprecated, message: "Extended event data are no longer supported.")
    @objc(extendedDataDate:) public class func extendedData(date: Date) -> [AnyHashable: Any] {
        return [:]
    }

    @available(*, deprecated, message: "Extended event data are no longer supported.")
    @objc(extendedDataLocationForLatitude:longitude:) public class func extendedData(latitude: Double, longitude: Double) -> [AnyHashable: Any] {
        return [:]
    }

    @available(*, deprecated, message: "Extended event data are no longer supported.")
    @objc(extendedDataCommerceWithTransactionID:affiliation:revenue:shipping:tax:currency:commerceItems:) public class func extendedData(transactionID: String?, affiliation: String?, revenue: NSNumber?, shipping: NSNumber?, tax: NSNumber?, currency: String?, commerceItems: [[AnyHashable: Any]]?) -> [AnyHashable: Any] {
        return [:]
    }

    @available(*, deprecated, message: "Extended event data are no longer supported.")
    @objc(extendedDataCommerceItemWithItemID:name:category:price:quantity:currency:) public class func extendedData(itemID: String?, name: String?, category: String?, price: NSNumber?, quantity: NSNumber?, currency: String?) -> [AnyHashable: Any] {
        return [:]
    }

    @available(*, deprecated, message: "This feature is not implemented and will always result in false.")
    @objc public func queryCanShowMessageCenter(completion: @escaping (Bool) -> Void) {
        completion(false)
    }

    @available(swift, deprecated: 5.0, message: "Use the method whose completion handler takes a Result<Bool, Error> parameter.")
    @objc(presentMessageCenterFromViewController:completion:)
    public func presentMessageCenterCompat(from viewController: UIViewController?, completion: ((Bool) -> Void)? = nil) {
        self.presentMessageCenter(from: viewController) { result in
            switch result {
            case .success(let didShow):
                completion?(didShow)

            default:
                completion?(false)
            }
        }
    }

    @objc(presentMessageCenterFromViewController:withCustomData:)
    public func presentMessageCenterCompat(from viewController: UIViewController?, withCustomData customData: [AnyHashable: Any]?) {
        self.presentMessageCenter(from: viewController, with: Self.convertCustomData(customData))
    }

    @available(swift, deprecated: 5.0, message: "Use the method whose completion handler takes a Result<Bool, Error> parameter.")
    @objc(presentMessageCenterFromViewController:withCustomData:completion:)
    public func presentMessageCenterCompat(from viewController: UIViewController?, withCustomData customData: [AnyHashable: Any]?, completion: ((Bool) -> Void)? = nil) {
        self.presentMessageCenter(from: viewController, with: Self.convertCustomData(customData)) { result in
            switch result {
            case .success(let didShow):
                completion?(didShow)

            default:
                completion?(false)
            }
        }
    }

    @available(*, deprecated, message: "This feature is not implemented and this method will always result in false.")
    @objc public func dismissMessageCenter(animated: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }

    @available(*, deprecated, message: "This feature is not implemented and this property will always return 0.")
    @objc public var unreadMessageCount: UInt {
        return 0
    }

    @available(*, deprecated, message: "This feature is not implemented and this property will return an empty view.")
    @objc public func unreadMessageCountAccessoryView(apptentiveHeart: Bool) -> UIView {
        return UIView(frame: .zero)
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func openAppStore() {
        assertionFailure("The public App Store feature is no longer supported.")
    }

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func setPushProvider(_ pushProvider: ApptentivePushProvider, deviceToken: Data) {}

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) -> Bool {
        return false
    }

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func didReceiveLocalNotification(_ notification: UILocalNotification, from viewController: UIViewController) -> Bool {
        return false
    }

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func didReceveUserNotificationResponse(_ response: UNNotificationResponse, from viewController: UIViewController?, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        return false
    }

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func didReceveUserNotificationResponse(_ response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) -> Bool {
        return false
    }

    @available(*, deprecated, message: "Push notification support is not yet available.")
    @objc public func willPresent(_ notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) -> Bool {
        return false
    }

    @available(*, deprecated, message: "Advertising identifier collection is not implemented.")
    @objc public var advertisingIdentifier: UUID? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "mParticleId has been renamed to mParticleID.")
    @objc public var mParticleId: String? {
        get {
            return self.mParticleID
        }
        set {
            self.mParticleID = newValue
        }
    }

    @available(*, deprecated, message: "Subscript the `personCustomData` property instead.")
    @objc public func removeCustomPersonData(withKey key: String) {
        self.personCustomData[key] = nil
    }

    @available(*, deprecated, message: "Subscript the `deviceCustomData` property instead.")
    @objc public func removeCustomDeviceData(withKey key: String) {
        self.deviceCustomData[key] = nil
    }

    @available(*, deprecated, message: "Subscript the `deviceCustomData` property instead.")
    @objc(addCustomDeviceDataString:withKey:) public func addCustomDeviceData(_ string: String, withKey key: String) {
        self.deviceCustomData[key] = string
    }

    @available(*, deprecated, message: "Subscript the `deviceCustomData` property instead.")
    @objc(addCustomDeviceDataNumber:withKey:) public func addCustomDeviceData(_ number: NSNumber, withKey key: String) {
        self.deviceCustomData[key] = number.doubleValue
    }

    @available(*, deprecated, message: "Subscript the `deviceCustomData` property instead.")
    @objc(addCustomDeviceDataBool:withKey:) public func addCustomDeviceData(_ boolValue: Bool, withKey key: String) {
        self.deviceCustomData[key] = boolValue
    }

    @available(*, deprecated, message: "Subscript the `personCustomData` property instead.")
    @objc(addCustomPersonDataString:withKey:) public func addCustomPersonData(_ string: String, withKey key: String) {
        self.personCustomData[key] = string
    }

    @available(*, deprecated, message: "Subscript the `personCustomData` property instead.")
    @objc(addCustomPersonDataNumber:withKey:) public func addCustomPersonData(_ number: NSNumber, withKey key: String) {
        self.personCustomData[key] = number.doubleValue
    }

    @available(*, deprecated, message: "Subscript the `personCustomData` property instead.")
    @objc(addCustomPersonDataBool:withKey:) public func addCustomPersonData(_ boolValue: Bool, withKey key: String) {
        self.personCustomData[key] = boolValue
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func dismissAllInteractions(animated: Bool) {
        assertionFailure("This method is no longer implemented.")
    }

    @available(*, deprecated, message: "Set style overrides in the UIKit+Apptentive extensions.")
    @objc public var styleSheet: Any? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func checkSDKConfiguration() {
        assertionFailure("This method is no longer implemented.")
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func logIn(withToken token: String, completion: @escaping (Bool, Error) -> Void) {
        assertionFailure("This method is no longer implemented.")
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func logOut() {
        assertionFailure("This method is no longer implemented.")
    }

    @available(*, deprecated, message: "Multiple users on the same device is no longer supported.")
    @objc public var authenticationFailureCallback: ApptentiveAuthenticationFailureCallback? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "This feature is no longer supported.")
    @objc public var preInteractionCallback: ApptentiveInteractionCallback? {
        get {
            nil
        }
        set {}
    }

    @available(*, deprecated, message: "This method is no longer implemented and will trigger an assertion failure.")
    @objc public func updateToken(_ token: String, completion: ((Bool) -> Void)? = nil) {
        assertionFailure("This method is no longer implemented.")
    }

    @available(*, deprecated, message: "Set the `logLevel` property on `ApptentiveLogger` or one of it's static log properties.")
    @objc public var logLevel: ApptentiveLogLevel {
        get {
            return .undefined
        }
        set {
            ApptentiveLogger.logLevel = newValue.logLevel
        }
    }

    private static func convertCustomData(_ legacyCustomData: [AnyHashable: Any]?) -> CustomData {
        guard let legacyCustomData = legacyCustomData else {
            return CustomData()
        }

        var migratedCustomData = CustomData()

        for (key, value) in legacyCustomData {
            guard let key = key as? String else {
                assertionFailure("Custom data keys must be strings.")
                continue
            }

            guard let value = value as? CustomDataCompatible else {
                assertionFailure("Custom data values must be strings, numbers, or booleans.")
                continue
            }

            migratedCustomData[key] = value
        }

        return migratedCustomData
    }
}

@available(*, deprecated, message: "Multiple users on the same device is no longer supported.")
public typealias ApptentiveAuthenticationFailureCallback = (ApptentiveAuthenticationFailureReason, String) -> Void

@available(*, deprecated, message: "This feature is no longer supported.")
public typealias ApptentiveInteractionCallback = (String, [AnyHashable: Any]?) -> Bool

@available(*, deprecated, message: "Multiple users on the same device is no longer supported.")
@objc public enum ApptentiveAuthenticationFailureReason: Int {
    /// An unknown authentication failure.
    case unknown = 0

    /// An invalid JWT algorithm was used.
    case invalidAlgorithm = 1

    /// A malformed JWT was encountered.
    case malformedToken = 2

    /// An invalid JWT was encountered.
    case invalidToken = 3

    /// A required subclaim was missing.
    case missingSubClaim = 4

    /// A subclaim didn't match the logged-in session.
    case mismatchedSubClaim = 5

    /// An invalid subclaim was encountered.
    case invalidSubClaim = 6

    /// The JWT expired.
    case expiredToken = 7

    /// The JWT was revoked.
    case revokedToken = 8

    /// The Apptentive App Key was missing.
    case missingAppKey = 9

    /// The Apptentive App Signature was missing
    case missingAppSignature = 10

    /// In invalid combination of an Apptentive App Key and an Apptentive App Signature was found.
    case invalidKeySignaturePair = 11
}

public class ApptentiveConfiguration: NSObject {
    /// The Apptentive App Key, obtained from your Apptentive dashboard.
    @objc public let apptentiveKey: String

    /// The Apptentive App Signature, obtained from your Apptentive dashboard.
    @objc public let apptentiveSignature: String

    /// The granularity of log messages to show.
    @available(*, deprecated, message: "Set the `logLevel` property on `ApptentiveLogger` or one of it's static log properties.")
    @objc public var logLevel: ApptentiveLogLevel = .warn

    /// If set, redacts potentially-sensitive information such as user data and credentials from logging.
    @available(*, deprecated, message: "This property is ignored. Log messages will be redacted unless the app has a debugger attached.")
    @objc public var shouldSanitizeLogMessages: Bool = true

    /// The server URL to use for API calls. Should only be used for testing.
    @available(*, deprecated, message: "This property is ignored. Use the designated initializer for `Apptentive` to set this.")
    @objc public var baseURL: URL? = nil

    /// The name of the distribution that includes the Apptentive SDK. For example "Cordova".
    @objc public var distributionName: String? = nil

    /// The version of the distribution that includes the Apptentive SDK.
    @objc public var distributionVersion: String? = nil

    /// The iTunes store app ID of the app (used for Apptentive rating prompt).
    @available(*, deprecated, message: "This property is ignored. An `SKStoreReviewController` will be used for all ratings.")
    @objc public var appID: String? = nil

    /// If set, shows a button in Surveys and Message Center that presents information about Apptentive including a link to our privacy policy.
    @available(*, deprecated, message: "This property is ignored. The info button no longer exists.")
    @objc public var showInfoButton: Bool = false

    /// If set, will show a link to terms and conditions in the bottom bar in Surveys.
    @available(*, deprecated, message: "This feature is currently not implemented.")
    @objc public var surveyTermsAndConditions: TermsAndConditions? = nil

    public required init?(apptentiveKey: String, apptentiveSignature: String) {
        self.apptentiveKey = apptentiveKey
        self.apptentiveSignature = apptentiveSignature
    }

    /// Returns an instance of the `ApptentiveConfiguration` class initialized with the specified parameters.
    /// - Parameters:
    ///   - apptentiveKey: The Apptentive App Key, obtained from your Apptentive dashboard.
    ///   - apptentiveSignature: The Apptentive App Signature, obtained from your Apptentive dashboard.
    /// - Returns: A configuration object initalized with the key and signature.
    // TODO: Figure out if this can be a convenience initializer instead.
    @objc public static func configuration(apptentiveKey key: String, apptentiveSignature signature: String) -> ApptentiveConfiguration {
        Self.init(apptentiveKey: key, apptentiveSignature: signature)!
    }
}

@available(*, deprecated, message: "Push notifications are not yet supported.")
@objc public enum ApptentivePushProvider: Int {
    /// Specifies the Apptentive push provider.
    case apptentive = 0

    /// Specifies the Urban Airship push provider.
    case urbanAirship = 1

    /// Specifies the Amazon Simple Notification Service push provider.
    case amazonSNS = 2

    /// Specifies the Parse push provider.
    case parse = 3
}

@available(*, deprecated, message: "Use the `LogLevel` enumeration to set the `logLevel` property on `ApptentiveLogger` or one of it's static log properties.")
@objc public enum ApptentiveLogLevel: UInt {
    /// Undefined.
    case undefined = 0

    /// Critical failure log messages.
    case crit = 1

    /// Error log messages.
    case error = 2

    /// Warning log messages.
    case warn = 3

    /// Informational log messages.
    case info = 4

    /// Log messages that are potentially useful for debugging.
    case debug = 5

    /// All possible log messages enabled.
    case verbose = 6

    internal var logLevel: LogLevel {
        switch self {
        case .undefined:
            return .info

        case .crit:
            return .critical

        case .error:
            return .error

        case .warn:
            return .warning

        case .info:
            return .info

        case .debug:
            return .debug

        case .verbose:
            return .debug
        }
    }
}

public class TermsAndConditions: NSObject {
    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public init(bodyText: String?, linkText: String?, linkURL: URL?) {
        self.bodyText = bodyText
        self.linkText = linkText
        self.linkURL = linkURL
    }

    public let bodyText: String?
    public let linkText: String?
    public let linkURL: URL?
}

@available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
public protocol ApptentiveStyle {
    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    func font(for textStyle: ApptentiveStyleIdentifier) -> UIFont

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    func color(for style: ApptentiveStyleIdentifier) -> UIColor
}

@available(*, deprecated, message: "This enumeration is provided for compatibility but this feature is not implemented.")
public enum ApptentiveStyleIdentifier {
    case body
    case headerTitle
    case headerMessage
    case messageDate
    case messageSender
    case messageStatus
    case messageCenterStatus
    case surveyInstructions
    case doneButton
    case button
    case submitButton
    case textInput
    case headerBackground
    case footerBackground
    case failure
    case separator
    case background
    case collectionBackground
    case textInputBackground
    case textInputPlaceholder
    case messageBackground
    case replyBackground
    case contextBackground
}

@available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
public class ApptentiveStyleSheet: ApptentiveStyle {
    internal init() {
        self.fontFamily = ""
        self.lightFaceAttribute = ""
        self.regularFaceAttribute = ""
        self.mediumFaceAttribute = ""
        self.boldFaceAttribute = ""
        self.primaryColor = .magenta
        self.secondaryColor = .magenta
        self.failureColor = .magenta
        self.backgroundColor = .magenta
        self.separatorColor = .magenta
        self.collectionBackgroundColor = .magenta
        self.placeholderColor = .magenta
        self.sizeAdjustment = 0
    }

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public func font(for textStyle: ApptentiveStyleIdentifier) -> UIFont {
        return UIFont()
    }

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public func color(for style: ApptentiveStyleIdentifier) -> UIColor {
        return UIColor()
    }

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public convenience init?(contentsOf stylePropertyListURL: URL) {
        self.init()
    }

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var fontFamily: String

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var lightFaceAttribute: String?

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var regularFaceAttribute: String?

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var mediumFaceAttribute: String?

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var boldFaceAttribute: String?

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var primaryColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var secondaryColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var failureColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var backgroundColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var separatorColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var collectionBackgroundColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var placeholderColor: UIColor

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public var sizeAdjustment: CGFloat

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public func setFontDescriptor(_ fontDescriptor: UIFontDescriptor, forStyle style: String) {}

    @available(*, deprecated, message: "This class is provided for compatibility but this feature is not implemented.")
    public func setColor(_ color: UIColor, forStyle style: String) {}
}
