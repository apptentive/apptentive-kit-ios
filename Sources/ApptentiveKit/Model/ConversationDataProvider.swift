//
//  ConversationDataProvider.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/29/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import OSLog

#if canImport(UIKit)
    import UIKit
#else
    import Foundation
#endif

#if canImport(CoreTelephony)
    import CoreTelephony
#endif

/// The portions of the Conversation Data Provider that provide information about the app.
protocol AppDataProviding: Sendable {
    var appStoreReceiptURL: URL? { get }
    var sdkVersion: Version { get }
    var distributionName: String? { get set }
    var distributionVersion: Version? { get set }
    var isDebugBuild: Bool { get }
    var isOverridingStyles: Bool { get set }

    var bundleIdentifier: String? { get }
    var version: Version? { get }
    var build: Version? { get }
    var deploymentTarget: String? { get }
    var compiler: String? { get }
    var platformBuild: String? { get }
    var platformName: String? { get }
    var platformVersion: String? { get }
    var sdkBuild: String? { get }
    var sdkName: String? { get }
    var xcode: String? { get }
    var xcodeBuild: String? { get }
}

/// The portions of the Conversation Data Provider that provide information about the device.
protocol DeviceDataProviding: Sendable {
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
    var remoteNotificationDeviceToken: Data? { get set }

    #if canImport(UIKit)
        var contentSizeCategory: UIContentSizeCategory { get set }
    #endif
}

typealias ConversationDataProviding = AppDataProviding & DeviceDataProviding

struct ConversationDataProvider: ConversationDataProviding {
    var sdkVersion: Version
    let appStoreReceiptURL: URL?
    var distributionName: String?
    var distributionVersion: Version?
    let isDebugBuild: Bool
    var isOverridingStyles: Bool
    let identifierForVendor: UUID?
    let osName: String
    let osVersion: Version
    let osBuild: Version
    let hardware: String
    let carrier: String?
    let localeIdentifier: String
    let localeRegionCode: String?
    let preferredLocalization: String?
    let timeZoneSecondsFromGMT: Int
    var remoteNotificationDeviceToken: Data?
    var contentSizeCategory: UIContentSizeCategory
    let bundleIdentifier: String?
    let version: Version?
    let build: Version?
    let deploymentTarget: String?
    let compiler: String?
    let platformBuild: String?
    let platformName: String?
    let platformVersion: String?
    let sdkBuild: String?
    let sdkName: String?
    let xcode: String?
    let xcodeBuild: String?

    @MainActor init() {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        self.appStoreReceiptURL = Bundle.main.appStoreReceiptURL

        #if targetEnvironment(macCatalyst)
            self.carrier = nil
        #else
            #if canImport(CoreTelephony)
                let telephonyNetworkInfo = CTTelephonyNetworkInfo()
                if let carriers = telephonyNetworkInfo.serviceSubscriberCellularProviders, carriers.count > 0 {
                    self.carrier = carriers.values.compactMap { $0.carrierName }.joined(separator: "|")
                } else {
                    self.carrier = nil
                }
            #else
                self.carrier = nil
            #endif
        #endif

        self.osBuild = Version(string: UIDevice.current.systemVersion)
        self.hardware = Self.getDeviceIdentifier()

        self.contentSizeCategory = UIApplication.shared.preferredContentSizeCategory

        #if DEBUG
            isDebugBuild = true
        #else
            isDebugBuild = false
        #endif

        self.isOverridingStyles = false

        #if canImport(UIKit)
            self.identifierForVendor = UIDevice.current.identifierForVendor
            self.osName = UIDevice.current.systemName
            self.osVersion = Version(string: UIDevice.current.systemVersion)
        #else
            self.isProtectedDataAvailable = true
            self.isInForeground = true
        #endif

        self.localeIdentifier = Locale.current.identifier
        self.localeRegionCode = Locale.current.regionCode
        self.preferredLocalization = Bundle.main.preferredLocalizations.first

        self.timeZoneSecondsFromGMT = TimeZone.current.secondsFromGMT()

        self.remoteNotificationDeviceToken = nil

        // Set the distribution name for non-plugin environments. Plugin environments will override this value later.
        #if COCOAPODS
            self.distributionName = "CocoaPods"
        #else
            if let _ = Bundle.apptentive.url(forResource: "SwiftPM", withExtension: "txt") {
                self.distributionName = "SwiftPM"
            } else if let url = Bundle.apptentive.url(forResource: "Distribution", withExtension: "plist"),
                let data = try? Data(contentsOf: url),
                let infoDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
                let distributionName = infoDictionary["ApptentiveDistributionName"] as? String
            {
                self.distributionName = distributionName
            } else {
                Logger.default.warning("ApptentiveKit framework is damaged! Missing ApptentiveDistributionName in Distribution.plist.")
                self.distributionName = "Unknown"
            }
        #endif

        // Set the version. First look for Version.plist, which is a workaround for Swift Package Manager.
        if let url = Bundle.apptentive.url(forResource: "Distribution", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let infoDictionary = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any],
            let versionString = infoDictionary["CFBundleShortVersionString"] as? String
        {
            self.sdkVersion = Version(string: versionString)
        } else {
            apptentiveCriticalError("Unable to read SDK version from ApptentiveKit's Info.plist file")
            self.sdkVersion = "Unavailable"
        }

        self.distributionVersion = self.sdkVersion

        self.bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String
        self.version = (infoDictionary["CFBundleShortVersionString"] as? String).flatMap { Version(string: $0) }
        self.build = (infoDictionary["CFBundleVersion"] as? String).flatMap { Version(string: $0) }
        self.deploymentTarget = infoDictionary["MinimumOSVersion"] as? String
        self.compiler = infoDictionary["DTCompiler"] as? String
        self.platformBuild = infoDictionary["DTPlatformBuild"] as? String
        self.platformName = infoDictionary["DTPlatformName"] as? String
        self.platformVersion = infoDictionary["DTPlatformVersion"] as? String
        self.sdkBuild = infoDictionary["DTSDKBuild"] as? String
        self.sdkName = infoDictionary["DTSDKName"] as? String
        self.xcode = infoDictionary["DTXcode"] as? String
        self.xcodeBuild = infoDictionary["DTXcodeBuild"] as? String
    }

    static func getDeviceIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)

        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        return machine
    }
}
