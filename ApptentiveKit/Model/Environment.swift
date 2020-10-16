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

protocol PlatformEnvironment {
    var fileManager: FileManager { get }
    var isInForeground: Bool { get }
    var isProtectedDataAvailable: Bool { get }

    func applicationSupportURL() throws -> URL
}

protocol AppEnvironment {
    var infoDictionary: [String: Any]? { get }
    var appStoreReceiptURL: URL? { get }
    var sdkVersion: Version { get }
    var distributionName: String? { get }
    var distributionVersion: Version? { get }
    var isDebugBuild: Bool { get }
}

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

protocol EnvironmentDelegate: AnyObject {
    func protectedDataDidBecomeAvailable(_ environment: Environment)
}

class Environment: ConversationEnvironment {
    let fileManager: FileManager
    var isProtectedDataAvailable: Bool

    let infoDictionary: [String: Any]?
    let appStoreReceiptURL: URL?

    let identifierForVendor: UUID?
    let osName: String
    let osVersion: Version
    let osBuild: Version
    let hardware: String

    var localeIdentifier: String
    var localeRegionCode: String?
    var preferredLocalization: String?
    var timeZoneSecondsFromGMT: Int

    var distributionName: String?
    var distributionVersion: Version?
    let isDebugBuild: Bool

    var carrier: String?
    var contentSizeCategory: UIContentSizeCategory

    #if canImport(CoreTelephony)
        let telephonyNetworkInfo: CTTelephonyNetworkInfo
    #endif

    weak var delegate: EnvironmentDelegate?

    lazy var sdkVersion: Version = {
        guard let versionString = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String else {
            assertionFailure("Unable to read SDK version from ApptentiveKit's Info.plist file")
            return "Unavailable"
        }

        return Version(string: versionString)
    }()

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
