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
import OSLog

extension Apptentive {
    @available(swift, deprecated: 1.0, message: "Use the 'register(with:completion:) method that takes an 'AppCredentials' argument.")
    @objc(registerWithConfiguration:completion:) public func register(with configuration: ApptentiveConfiguration, completion: (@Sendable (Bool) -> Void)? = nil) {
        if let distributionName = configuration.distributionName {
            self.distributionName = distributionName
        }

        if let distributionVersion = configuration.distributionVersion {
            self.distributionVersion = distributionVersion
        }

        let region = configuration.baseURL.flatMap({ Region(apiBaseURL: $0) }) ?? .us

        self.register(with: .init(key: configuration.apptentiveKey, signature: configuration.apptentiveSignature), region: region) { result in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @objc(engage:fromViewController:) public func engage(_ event: String, fromViewController viewController: UIViewController?) {
        self.engage(event: Event(name: event), from: viewController)
    }

    @objc(engage:fromViewController:completion:) public func engage(_ event: String, fromViewController viewController: UIViewController?, completion: (@Sendable (Bool) -> Void)? = nil) {
        self.engage(event: Event(name: event), from: viewController) { (result) in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Create an 'Event' object and subscript its 'customData' property.")
    @objc(engage:withCustomData:fromViewController:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, from viewController: UIViewController?) {
        var event = Event(name: event)
        event.customData = Self.convertLegacyCustomData(customData)
        self.engage(event: event, from: viewController, completion: nil)
    }

    @available(swift, deprecated: 1.0, message: "Create an 'Event' object and subscript its 'customData' property.")
    @objc(engage:withCustomData:fromViewController:completion:) public func engage(event: String, withCustomData customData: [AnyHashable: Any]?, from viewController: UIViewController?, completion: (@Sendable (Bool) -> Void)? = nil) {
        var event = Event(name: event)
        event.customData = Self.convertLegacyCustomData(customData)
        self.engage(event: event, from: viewController) { (result) in
            switch result {
            case .success:
                completion?(true)

            case .failure:
                completion?(false)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Use the 'canShowInteraction(event:)' method instead.")
    @objc public func queryCanShowInteraction(forEvent event: String, completion: @Sendable @escaping (Bool) -> Void) {
        let event = Event(name: event)
        self.canShowInteraction(event: event) { result in
            switch result {
            case .success(let canShowInteraction):
                completion(canShowInteraction)
            case .failure(_):
                completion(false)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Use the 'canShowMessageCenter()' method instead.")
    @objc public func queryCanShowMessageCenter(completion: @Sendable @escaping (Bool) -> Void) {
        self.canShowMessageCenter() { result in
            switch result {
            case .success(let canShowMessageCenter):
                completion(canShowMessageCenter)
            case .failure(_):
                completion(false)
            }
        }
    }

    @objc(presentMessageCenterFromViewController:)
    public func presentMessageCenterCompat(from viewController: UIViewController?) {
        self.presentMessageCenter(from: viewController)
    }

    @available(swift, deprecated: 1.0, message: "Use the async version of this method.")
    @objc(presentMessageCenterFromViewController:completion:)
    public func presentMessageCenterCompat(from viewController: UIViewController?, completion: (@Sendable (Bool) -> Void)? = nil) {
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
        self.presentMessageCenter(from: viewController, with: Self.convertLegacyCustomData(customData))
    }

    @available(swift, deprecated: 1.0, message: "Use the async version of this method.")
    @objc(presentMessageCenterFromViewController:withCustomData:completion:)
    public func presentMessageCenterCompat(from viewController: UIViewController?, withCustomData customData: [AnyHashable: Any]?, completion: (@Sendable (Bool) -> Void)? = nil) {
        self.presentMessageCenter(from: viewController, with: Self.convertLegacyCustomData(customData)) { result in
            switch result {
            case .success(let didShow):
                completion?(didShow)

            default:
                completion?(false)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'personCustomData' property instead.")
    @objc public func removeCustomPersonData(withKey key: String) {
        self.personCustomData[key] = nil
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'deviceCustomData' property instead.")
    @objc public func removeCustomDeviceData(withKey key: String) {
        self.deviceCustomData[key] = nil
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'deviceCustomData' property instead.")
    @objc(addCustomDeviceDataString:withKey:) public func addCustomDeviceData(_ string: String, withKey key: String) {
        self.deviceCustomData[key] = string
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'deviceCustomData' property instead.")
    @objc(addCustomDeviceDataNumber:withKey:) public func addCustomDeviceData(_ number: NSNumber, withKey key: String) {
        self.deviceCustomData[key] = number.doubleValue
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'deviceCustomData' property instead.")
    @objc(addCustomDeviceDataBool:withKey:) public func addCustomDeviceData(_ boolValue: Bool, withKey key: String) {
        self.deviceCustomData[key] = boolValue
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'personCustomData' property instead.")
    @objc(addCustomPersonDataString:withKey:) public func addCustomPersonData(_ string: String, withKey key: String) {
        self.personCustomData[key] = string
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'personCustomData' property instead.")
    @objc(addCustomPersonDataNumber:withKey:) public func addCustomPersonData(_ number: NSNumber, withKey key: String) {
        self.personCustomData[key] = number.doubleValue
    }

    @available(swift, deprecated: 1.0, message: "Subscript the 'personCustomData' property instead.")
    @objc(addCustomPersonDataBool:withKey:) public func addCustomPersonData(_ boolValue: Bool, withKey key: String) {
        self.personCustomData[key] = boolValue
    }

    @available(swift, deprecated: 1.0, message: "Use the method whose completion handler takes a Result<Void, Error> parameter.")
    @objc public func logIn(withToken token: String, completion: @Sendable @escaping (Bool, Error?) -> Void) {
        self.logIn(with: token) { result in
            switch result {
            case .success:
                completion(true, nil)

            case .failure(let error):
                completion(false, error)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Use the method whose completion handler takes a Result<Void, Error> parameter.")
    @objc public func logOut() {
        self.logOut(completion: nil)
    }

    @available(swift, deprecated: 1.0, message: "Assign an object that conforms to the 'ApptentiveDelegate' protocol to the Apptentive instance's 'delegate' property.")
    @objc public var authenticationFailureCallback: ApptentiveAuthenticationFailureCallback? {
        get {
            return Self.compatibilityDelegate.authenticationFailureCallback
        }
        set {
            Self.compatibilityDelegate.authenticationFailureCallback = newValue
        }
    }

    @available(swift, deprecated: 1.0, message: "Use the method whose completion handler takes a Result<Void, Error> parameter.")
    @objc public func updateToken(_ token: String, completion: (@Sendable (Bool) -> Void)? = nil) {
        self.updateToken(token) { (result: Result<Void, Error>) in
            switch result {
            case .success:
                completion?(true)

            case .failure(let error):
                Logger.default.error("Error when attempting to update token: \(error)")
                completion?(false)
            }
        }
    }

    @available(swift, deprecated: 1.0, message: "Log level is no longer supported. Use the filtering in Xcode or Console app.")
    @objc public var logLevel: ApptentiveLogLevel {
        get {
            return .undefined
        }
        set {
        }
    }

    nonisolated static func convertLegacyCustomData(_ legacyCustomData: [AnyHashable: Any]?) -> CustomData {
        var result = CustomData()

        if let legacyCustomData = legacyCustomData {
            for (key, value) in legacyCustomData {
                guard let key = key as? String else {
                    apptentiveCriticalError("Custom data keys must be strings.")
                    continue
                }

                switch value {
                case let bool as Bool:
                    result[key] = bool

                case let int as Int:
                    result[key] = int

                case let double as Double:
                    result[key] = double

                case let string as String:
                    result[key] = string

                default:
                    Logger.default.warning("Unable to migrate custom data value “\(String(describing: value))” for key “\(key)”")
                    break
                }
            }
        }

        return result
    }

    @available(swift, deprecated: 1.0, message: "(Needed to silence deprecation warning elsewhere)")
    private static let compatibilityDelegate = CompatibilityDelegate()

    @available(swift, deprecated: 1.0, message: "Use the 'AuthenticationFailureReason' enumeration.")
    class CompatibilityDelegate: ApptentiveDelegate {
        func authenticationDidFail(with error: Error) {
            let (reason, responseString) = Self.convertAuthenticationFailureError(error)

            self.authenticationFailureCallback?(reason, responseString)
        }

        var authenticationFailureCallback: ApptentiveAuthenticationFailureCallback?

        static func convertAuthenticationFailureError(_ error: Error) -> (ApptentiveAuthenticationFailureReason, String?) {
            if case .authenticationFailed(reason: let reason, responseString: let responseString) = error as? ApptentiveError {
                switch reason {
                case .invalidAlgorithm:
                    return (ApptentiveAuthenticationFailureReason.invalidAlgorithm, responseString)
                case .malformedToken:
                    return (ApptentiveAuthenticationFailureReason.malformedToken, responseString)
                case .invalidToken:
                    return (ApptentiveAuthenticationFailureReason.invalidToken, responseString)
                case .missingSubClaim:
                    return (ApptentiveAuthenticationFailureReason.missingSubClaim, responseString)
                case .mismatchedSubClaim:
                    return (ApptentiveAuthenticationFailureReason.mismatchedSubClaim, responseString)
                case .invalidSubClaim:
                    return (ApptentiveAuthenticationFailureReason.invalidSubClaim, responseString)
                case .expiredToken:
                    return (ApptentiveAuthenticationFailureReason.expiredToken, responseString)
                case .revokedToken:
                    return (ApptentiveAuthenticationFailureReason.revokedToken, responseString)
                case .missingAppKey:
                    return (ApptentiveAuthenticationFailureReason.missingAppKey, responseString)
                case .missingAppSignature:
                    return (ApptentiveAuthenticationFailureReason.missingAppSignature, responseString)
                case .invalidKeySignaturePair:
                    return (ApptentiveAuthenticationFailureReason.invalidKeySignaturePair, responseString)
                default:
                    return (.unknown, responseString)
                }
            } else {
                return (.unknown, "")
            }
        }
    }
}

extension UIButton {
    @available(swift, deprecated: 1.0, message: "Set the 'apptentiveStyle' property to 'ApptentiveButtonStyle.pill'.")
    /// Magic value for specifying a pill-style button (corner radius is half the height).
    @objc public static let apptentivePillRadius: CGFloat = 15411

    @available(swift, deprecated: 1.0, message: "Use the 'apptentiveStyle' property.")
    /// The corner radius to use for the submit button in surveys.
    @objc public static var apptentiveCornerRadius: CGFloat {
        get {
            switch self.apptentiveStyle {
            case .pill:
                return self.apptentivePillRadius

            case .radius(let radius):
                return radius
            }
        }
        set {
            if newValue == apptentivePillRadius {
                self.apptentiveStyle = .pill
            } else {
                self.apptentiveStyle = .radius(newValue)
            }
        }
    }
}

extension UITableView {
    @available(swift, deprecated: 1.0, message: "Use the 'apptentive' property on 'UITableView.Style'.")
    /// The table view style to use for Survey interactions.
    @objc public static var apptentiveStyle: Int {
        get {
            return UITableView.Style.apptentive.rawValue
        }
        set {
            UITableView.Style.apptentive = UITableView.Style(rawValue: newValue) ?? .grouped
        }
    }
}

extension UIViewController {
    @available(swift, deprecated: 1.0, message: "Use the 'apptentive' property on 'UIModalPresentationStyle'.")
    /// The modal presentation style for presenting Message Center and Survey interactions.
    @objc public var apptentiveModalPresentationStyle: UIModalPresentationStyle {
        get {
            return UIModalPresentationStyle.apptentive
        }
        set {
            UIModalPresentationStyle.apptentive = newValue
        }
    }
}

@available(swift, deprecated: 1.0, message: "Use the 'AuthenticationFailureReason' enumeration.")
public typealias ApptentiveAuthenticationFailureCallback = (ApptentiveAuthenticationFailureReason, String?) -> Void

@available(swift, deprecated: 1.0, message: "Use the 'AuthenticationFailureReason' enumeration.")
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

@available(swift, deprecated: 1.0, message: "Set the properties from this class on the 'Apptentive' object directly.")
public class ApptentiveConfiguration: NSObject {
    /// The Apptentive App Key, obtained from your Apptentive dashboard.
    @objc public let apptentiveKey: String

    /// The Apptentive App Signature, obtained from your Apptentive dashboard.
    @objc public let apptentiveSignature: String

    /// The granularity of log messages to show.
    @available(*, deprecated, message: "Logging now uses iOS's Unified Logging features so logs are no longer filtered by the SDK.")
    @objc public var logLevel: ApptentiveLogLevel = .warn

    /// If set, redacts potentially-sensitive information such as user data and credentials from logging.
    @available(*, deprecated, message: "Logging now uses iOS's Unified Logging features so redaction of sensitive information is handled automatically.")
    @objc public var shouldSanitizeLogMessages: Bool = true

    /// The server URL to use for API calls. Should only be used for testing.
    @objc public var baseURL: URL? = nil

    /// The name of the distribution that includes the Apptentive SDK. For example "Cordova".
    @available(swift, deprecated: 1.0, message: "Set the 'distributionName' property on 'Apptentive' directly before calling 'register(with:completion)'.")
    @objc public var distributionName: String? = nil

    /// The version of the distribution that includes the Apptentive SDK.
    @available(swift, deprecated: 1.0, message: "Set the 'distributionVersion' property on 'Apptentive' directly before calling 'register(with:completion)'.")
    @objc public var distributionVersion: String? = nil

    @objc(initWithApptentiveKey:apptentiveSignature:) public required init?(apptentiveKey: String, apptentiveSignature: String) {
        self.apptentiveKey = apptentiveKey
        self.apptentiveSignature = apptentiveSignature
    }

    /// Returns an instance of the `ApptentiveConfiguration` class initialized with the specified parameters.
    /// - Parameters:
    ///   - key: The Apptentive App Key, obtained from your Apptentive dashboard.
    ///   - signature: The Apptentive App Signature, obtained from your Apptentive dashboard.
    /// - Returns: A configuration object initalized with the key and signature.
    @objc public static func configuration(apptentiveKey key: String, apptentiveSignature signature: String) -> ApptentiveConfiguration {
        Self.init(apptentiveKey: key, apptentiveSignature: signature)!
    }
}

@available(*, deprecated, message: "The SDK now uses Unified Logging, so logs are filtered by the logging system.")
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
}
