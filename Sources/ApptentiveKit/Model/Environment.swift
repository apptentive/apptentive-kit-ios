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

#if canImport(StoreKit)
    import StoreKit
#endif

/// The portions of the Environment that provide access to platform features.
protocol PlatformEnvironment {
    var fileManager: FileManager { get }
    var isInForeground: Bool { get }
    var isProtectedDataAvailable: Bool { get }
    var delegate: EnvironmentDelegate? { get set }

    func applicationSupportURL() throws -> URL
    func requestReview(completion: @escaping (Bool) -> Void)
    func open(_ url: URL, completion: @escaping (Bool) -> Void)
    func cachesURL() throws -> URL

    func startBackgroundTask()
    func endBackgroundTask()
}

/// The portions of the Environment that provide information about the app.
protocol AppEnvironment {
    var infoDictionary: [String: Any]? { get }
    var appStoreReceiptURL: URL? { get }
    var sdkVersion: Version { get }
    var distributionName: String? { get set }
    var distributionVersion: Version? { get set }
    var isDebugBuild: Bool { get }
    var isTesting: Bool { get }
    var appDisplayName: String { get }
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

typealias GlobalEnvironment = DeviceEnvironment & AppEnvironment & PlatformEnvironment

/// Allows the Environment to communicate changes.
protocol EnvironmentDelegate: AnyObject {

    /// Notifies the receiver that access to protected data (from the encrypted filesystem) is now available.
    /// - Parameter environment: The environment calling the method.
    func protectedDataDidBecomeAvailable(_ environment: GlobalEnvironment)

    /// Notifies the receiver that access to protected data (from the encrypted filesystem) will no longer be available.
    /// - Parameter environment: The environment calling the method.
    func protectedDataWillBecomeUnavailable(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application will enter the foreground.
    /// - Parameter environment: The environment calling the method.
    func applicationWillEnterForeground(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application did enter the background.
    /// - Parameter environment: The environment calling the method.
    func applicationDidEnterBackground(_ environment: GlobalEnvironment)

    /// Notifies the receiver that the application will terminate.
    /// - Parameter environment: The environment calling the method.
    func applicationWillTerminate(_ environment: GlobalEnvironment)

}

/// Provides access to platform, device, and operating system information.
///
/// Allows these values to be injected as a dependency to aid in testing.
class Environment: GlobalEnvironment {

    /// Whether the apptentive theme is set to `none` and is being overidden.
    var isOverridingStyles: Bool

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

    /// The display name of the app.
    let appDisplayName: String

    /// The mobile telephone carrier that the device is connected to, if any.
    var carrier: String?

    /// The dynamic text size selected by the user.
    var contentSizeCategory: UIContentSizeCategory

    #if targetEnvironment(macCatalyst)
    #else
        #if canImport(CoreTelephony)
            /// The current telephony network information.
            let telephonyNetworkInfo: CTTelephonyNetworkInfo
        #endif
    #endif

    /// Whether the application is in the foreground.
    var isInForeground: Bool

    /// Checks the environment to see if testing is taking place.
    var isTesting: Bool

    /// The delegate to notify when aspects of the environment change.
    weak var delegate: EnvironmentDelegate?

    /// The version of the SDK (read from the SDK framework's Info.plist).
    lazy var sdkVersion: Version = {
        // First look for Version.plist, which is a workaround for Swift Package Manager.
        guard let url = Bundle.module.url(forResource: "Distribution", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let infoDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let versionString = infoDictionary["CFBundleShortVersionString"] as? String
        else {
            apptentiveCriticalError("Unable to read SDK version from ApptentiveKit's Info.plist file")
            return "Unavailable"
        }

        if let infoPListVersionString = Bundle.module.infoDictionary?["CFBundleShortVersionString"] as? String {
            if infoPListVersionString != versionString {
                ApptentiveLogger.default.warning("ApptentiveKit framework is damaged! Version in Info.plist (\(infoPListVersionString)) does not match SDK version (\(versionString))")
            }
        }

        return Version(string: versionString)
    }()

    /// Initializes a new environment based on values captured from the operating system.
    init() {
        self.fileManager = FileManager.default
        self.isOverridingStyles = false
        self.infoDictionary = Bundle.main.infoDictionary
        let localizedInfoDictionary = Bundle.main.localizedInfoDictionary
        self.appStoreReceiptURL = Bundle.main.appStoreReceiptURL

        let possibleDisplayNames: [String?] = [
            localizedInfoDictionary?["CFBundleDisplayName"] as? String,
            localizedInfoDictionary?["CFBundleName"] as? String,
            self.infoDictionary?["CFBundleDisplayName"] as? String,
            self.infoDictionary?["CFBundleName"] as? String,
        ]

        self.appDisplayName = possibleDisplayNames.compactMap { $0 }.first ?? "App"

        #if canImport(CoreTelephony)
            self.telephonyNetworkInfo = CTTelephonyNetworkInfo()
            if #available(iOS 12.0, *) {
                if let carriers = telephonyNetworkInfo.serviceSubscriberCellularProviders, carriers.count > 0 {
                    self.carrier = carriers.values.compactMap({ $0.carrierName }).joined(separator: "|")
                }
            #endif
        #endif

        self.osBuild = Version(string: Sysctl.osVersion)
        self.hardware = Sysctl.model

        self.contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        #if DEBUG
            isDebugBuild = true
        #else
            isDebugBuild = false
        #endif

        self.isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

        #if canImport(UIKit)
            self.identifierForVendor = UIDevice.current.identifierForVendor
            self.osName = UIDevice.current.systemName
            self.osVersion = Version(string: UIDevice.current.systemVersion)

            self.isProtectedDataAvailable = UIApplication.shared.isProtectedDataAvailable
            self.isInForeground = UIApplication.shared.applicationState != .background
        #else
            self.isProtectedDataAvailable = true
            self.isInForeground = true
        #endif

        self.localeIdentifier = Locale.current.identifier
        self.localeRegionCode = Locale.current.regionCode
        self.preferredLocalization = Bundle.main.preferredLocalizations.first

        self.timeZoneSecondsFromGMT = TimeZone.current.secondsFromGMT()

        #if canImport(UIKit)
            NotificationCenter.default.addObserver(self, selector: #selector(protectedDataDidBecomeAvailable(notification:)), name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(protectedDataWillBecomeUnavailable(notification:)), name: UIApplication.protectedDataWillBecomeUnavailableNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        #endif

        // Set the distribution name for non-plugin environments. Plugin environments will override this value later.
        #if COCOAPODS
            self.distributionName = "CocoaPods"
        #else
            if let _ = Bundle.module.url(forResource: "SwiftPM", withExtension: "txt") {
                self.distributionName = "SwiftPM"
            } else if let url = Bundle.module.url(forResource: "Distribution", withExtension: "plist"),
                let data = try? Data(contentsOf: url),
                let infoDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                let distributionName = infoDictionary["ApptentiveDistributionName"] as? String
            {
                self.distributionName = distributionName
            } else {
                ApptentiveLogger.default.warning("ApptentiveKit framework is damaged! Missing ApptentiveDistributionName in Distribution.plist.")
                self.distributionName = "Unknown"
            }
        #endif

        self.distributionVersion = self.sdkVersion
    }

    /// Retrieves URL of the Application Support directory in the app's data container.
    /// - Throws: An error if the directory can not be found.
    /// - Returns: A file URL pointing to the directory.
    func applicationSupportURL() throws -> URL {
        return try self.fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }

    /// Retrieves URL of the Caches directory in the app's data container.
    /// - Throws: An error if the directory cannot be found.
    /// - Returns: A file URL pointing to the directory.
    func cachesURL() throws -> URL {
        return try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        //        let cachesURL = self.fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        //        return cachesURL[0]
    }

    /// Requests a review using `SKStoreReviewController`.
    ///
    /// If no review window appears within 1 second of the request, assume the request was denied.
    /// - Parameter completion: Called with a value indicating whether the review request was shown.
    func requestReview(completion: @escaping (Bool) -> Void) {
        #if canImport(StoreKit)
            var didShow = false

            // Prepare to observe when a window appears.
            NotificationCenter.default.addObserver(forName: UIWindow.didBecomeVisibleNotification, object: nil, queue: nil) { (notification) in
                if let object = notification.object, String(describing: type(of: object)).hasPrefix("SKStoreReview") {
                    // If the window looks store-review-related, note that the system showed the review request.
                    didShow = true
                }
            }

            // Request a review.
            SKStoreReviewController.requestReview()

            // Wait up to 1 second for the review window to appear before giving up.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
                NotificationCenter.default.removeObserver(self, name: UIWindow.didBecomeVisibleNotification, object: nil)

                completion(didShow)
            }
        #else
            completion(false)
        #endif
    }

    /// Asks the system to open the specified URL.
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: Called with a value indicating whether the URL was successfully opened.
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        #if canImport(UIKit)
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        #else
            completion(false)
        #endif
    }

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    func startBackgroundTask() {
        #if canImport(UIKit)
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.apptentive.feedback") {
                self.endBackgroundTask()
            }

            ApptentiveLogger.default.debug("Started background task with ID \(String(describing: self.backgroundTaskIdentifier)).")
        #endif
    }

    func endBackgroundTask() {
        guard let backgroundTaskIdentifier = self.backgroundTaskIdentifier else {
            return apptentiveCriticalError("Expected to have background task identifier.")
        }

        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        ApptentiveLogger.default.debug("Ended background task with ID \(String(describing: self.backgroundTaskIdentifier)).")
    }

    #if canImport(UIKit)
        @objc func protectedDataDidBecomeAvailable(notification: Notification) {
            self.isProtectedDataAvailable = true
            delegate?.protectedDataDidBecomeAvailable(self)
        }

        @objc func protectedDataWillBecomeUnavailable(notification: Notification) {
            self.isProtectedDataAvailable = false
            delegate?.protectedDataWillBecomeUnavailable(self)
        }

        @objc func applicationWillEnterForeground(notification: Notification) {
            delegate?.applicationWillEnterForeground(self)
            self.isInForeground = true
        }

        @objc func applicationDidEnterBackground(notification: Notification) {
            delegate?.applicationDidEnterBackground(self)
            self.isInForeground = false
        }

        @objc func applicationWillTerminate(notification: Notification) {
            delegate?.applicationWillTerminate(self)
            self.isInForeground = false
        }
    #endif
}
