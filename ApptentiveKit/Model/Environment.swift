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

protocol AppEnvironment {
    var infoDictionary: [String: Any]? { get }
    var appStoreReceiptURL: URL? { get }
    var sdkVersion: String { get }
    var distributionName: String? { get }
    var distributionVersion: String? { get }
    var isDebugBuild: Bool { get }
}

protocol DeviceEnvironment {
    var identifierForVendor: UUID? { get }
    var osName: String { get }
    var osVersion: String { get }
    var osBuild: String { get }
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

class Environment: ConversationEnvironment {
    let infoDictionary: [String: Any]?
    let appStoreReceiptURL: URL?

    let identifierForVendor: UUID?
    let osName: String
    let osVersion: String
    let osBuild: String
    let hardware: String

    var localeIdentifier: String
    var localeRegionCode: String?
    var preferredLocalization: String?
    var timeZoneSecondsFromGMT: Int

    var distributionName: String?
    var distributionVersion: String?
    let isDebugBuild: Bool

    var carrier: String?
    var contentSizeCategory: UIContentSizeCategory

    #if canImport(CoreTelephony)
        let telephonyNetworkInfo: CTTelephonyNetworkInfo
    #endif

    lazy var sdkVersion: String = {
        guard let versionString = Bundle(for: type(of: self)).infoDictionary?["CFBundleShortVersionString"] as? String else {
            assertionFailure("Unable to read SDK version from ApptentiveKit's Info.plist file")
            return "Unavailable"
        }

        return versionString
    }()

    init() {
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

        self.osBuild = Sysctl.osVersion
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
            self.osVersion = UIDevice.current.systemVersion
        #endif

        self.localeIdentifier = Locale.current.identifier
        self.localeRegionCode = Locale.current.regionCode
        self.preferredLocalization = Bundle.main.preferredLocalizations.first

        self.timeZoneSecondsFromGMT = TimeZone.current.secondsFromGMT()
    }
}
