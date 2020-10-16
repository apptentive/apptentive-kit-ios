//
//  Environment.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/8/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

#if canImport(UIKit)
    import UIKit
#endif

#if canImport(CoreTelephony)
    import CoreTelephony
#endif

/// The portions of the Environment that provide access to platform features.
protocol PlatformEnvironment {
    var fileManager: FileManager { get }
    var isInForeground: Bool { get }
    var isProtectedDataAvailable: Bool { get }

    func applicationSupportURL() throws -> URL
}

/// The portions of the Environment that provide information about the app.
protocol AppEnvironment {
    var infoDictionary: [String: Any]? { get }
    var appStoreReceiptURL: URL? { get }
    var sdkVersion: Version { get }
    var distributionName: String? { get }
    var distributionVersion: Version? { get }
    var isDebugBuild: Bool { get }
}

/// The portions of the Environment that provide information about the device.
protocol DeviceEnvironment {
    var identifierForVendor: UUID? { get }
    var osName: String { get }
    var osVersion: Version { get }
    var osBuild: Version { get }
    var hardware: String { get }
    var carrier: String? { get }
    var localeIdentifier: String { get }
    var localeRegionCode: String? { get }
    var preferredLocalization: String? { get }
    var timeZoneSecondsFromGMT: Int { get }

    #if canImport(UIKit)
        var contentSizeCategory: UIContentSizeCategory { get }
    #endif
}

/// Allows the Environment to communicate changes.
protocol EnvironmentDelegate: AnyObject {

    /// Notifies the receiver that access to protected data (from the encrypted filesystem) is now available.
    /// - Parameter environment: The environment calling the method.
    func protectedDataDidBecomeAvailable(_ environment: Environment)
}

/// Provides access to platform, device, and operating system information.
///
/// Allows these values to be injected as a dependency to aid in testing.
class Environment: ConversationEnvironment {

    /// The file manager that should be used when interacting with the filesystem.
    let fileManager: FileManager

    /// Whether the app has access to the encrypted filesystem.
    var isProtectedDataAvailable: Bool

    /// A dictionary providing information about the app, based on the `Bundle` object's `infoDictionary` property.
    let infoDictionary: [String: Any]?

    /// A file URL that points to the App Store receipt in the app bundle.
    let appStoreReceiptURL: URL?

    /// An identifier that uniquely identifies the device and is consistent across multiple apps from the same vendor.
    let identifierForVendor: UUID?

    /// The name of the operating system.
    let osName: String

    /// The version of the operating system.
    let osVersion: Version

    /// The build of the operating system.
    let osBuild: Version

    /// The internal name of the device (e.g. "iPhone8,2").
    let hardware: String

    /// The identifier for the locale (e.g. "en_US").
    var localeIdentifier: String

    /// The region code for the locale (e.g. "US").
    var localeRegionCode: String?

    /// The code for most preferred language common to the app's localizations and the device's settings.
    var preferredLocalization: String?

    /// The offset (in seconds) between the device's time zone and GMT.
    var timeZoneSecondsFromGMT: Int

    /// The name of the method by which the SDK was distributed (e.g. "Source", "React Native").
    var distributionName: String?

    /// The version of the distribution that the SDK was included in (the same as the SDK version unless it is embedded in another distribution).
    var distributionVersion: Version?

    /// Whether the SDK was built in a debug configuration.
    let isDebugBuild: Bool

    /// The mobile telephone carrier that the device is connected to, if any.
    var carrier: String?

    /// The dynamic text size selected by the user.
    var contentSizeCategory: UIContentSizeCategory

    #if canImport(CoreTelephony)
        /// The current telephony network information.
        let telephonyNetworkInfo: CTTelephonyNetworkInfo
    #endif

    /// The delegate to notify when aspects of the environment change.
    weak var delegate: EnvironmentDelegate?

    /// The version of the SDK (read from the SDK framework's Info.plist).
    lazy var sdkVersion: Version = {
        guard let versionString = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String else {
            assertionFailure("Unable to read SDK version from ApptentiveKit's Info.plist file")
            return "Unavailable"
        }

        return Version(string: versionString)
    }()

    /// Initializes a new environment based on values captured from the operating system.
    init() {
        self.fileManager = FileManager.default

        self.infoDictionary = Bundle.main.infoDictionary
        self.appStoreReceiptURL = Bundle.main.appStoreReceiptURL

        #if canImport(CoreTelephony)
            self.telephonyNetworkInfo = CTTelephonyNetworkInfo()
            if #available(iOS 12.0, *) {
                self.carrier = telephonyNetworkInfo.serviceSubscriberCellularProviders?.values.compactMap({ $0.carrierName }).joined(separator: ", ")
            } else {
                self.carrier = telephonyNetworkInfo.subscriberCellularProvider?.carrierName
            }
        #endif

        self.osBuild = Version(string: Sysctl.osVersion)
        self.hardware = Sysctl.model

        self.contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        #if DEBUG
            isDebugBuild = true
        #else
            isDebugBuild = false
        #endif

        #if canImport(UIKit)
            self.identifierForVendor = UIDevice.current.identifierForVendor
            self.osName = UIDevice.current.systemName
            self.osVersion = Version(string: UIDevice.current.systemVersion)

            self.isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
        #else
            self.isProtectedDataAvailable = true
        #endif

        self.localeIdentifier = Locale.current.identifier
        self.localeRegionCode = Locale.current.regionCode
        self.preferredLocalization = Bundle.main.preferredLocalizations.first

        self.timeZoneSecondsFromGMT = TimeZone.current.secondsFromGMT()

        #if canImport(UIKit)
            NotificationCenter.default.addObserver(self, selector: #selector(protectedDataDidBecomeAvailable(notification:)), name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
        #endif
    }

    /// Retrieves URL of the Application Support directory in the app's data container.
    /// - Throws: An error if the directory can not be found.
    /// - Returns: A file URL pointing to the directory.
    func applicationSupportURL() throws -> URL {
        return try self.fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    #if canImport(UIKit)
        @objc func protectedDataDidBecomeAvailable(notification: Notification) {
            self.isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
            delegate?.protectedDataDidBecomeAvailable(self)
        }
    #endif
}
