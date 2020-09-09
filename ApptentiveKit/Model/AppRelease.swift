//
//  AppRelease.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct AppRelease: Codable {
    let type: String = "ios"
    var bundleIdentifier: String?
    var version: String?
    var build: String?
    var hasAppStoreReceipt: Bool = false
    var isDebugBuild: Bool = false
    var isOverridingStyles: Bool = false
    var compiler: String?
    var platformBuild: String?
    var platformName: String?
    var platformVersion: String?
    var sdkBuild: String?
    var sdkName: String?
    var xcode: String?
    var xcodeBuild: String?
    var isUpdatedVersion: Bool = false
    var isUpdatedBuild: Bool = false
    let installTime: Date = Date()
    var versionInstallTime: Date = Date()
    var buildInstallTime: Date = Date()
    var sdkVersion: String
    var sdkProgrammingLanguage: String
    var sdkAuthorName: String
    var sdkPlatform: String
    var sdkDistributionName: String?
    var sdkDistributionVersion: String?

    init(environment: AppEnvironment) {
        if let infoDictionary = environment.infoDictionary {
            self.bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String

            if let versionString = infoDictionary["CFBundleShortVersionString"] as? String {
                self.version = versionString
            }

            if let buildString = infoDictionary["CFBundleVersion"] as? String {
                self.build = buildString
            }

            self.compiler = infoDictionary["DTCompiler"] as? String
            self.platformBuild = infoDictionary["DTPlatformBuild"] as? String
            self.platformName = infoDictionary["DTPlatformName"] as? String
            self.platformVersion = infoDictionary["DTPlatformVersion"] as? String
            self.sdkBuild = infoDictionary["DTSDKBuild"] as? String
            self.sdkName = infoDictionary["DTSDKName"] as? String
            self.xcode = infoDictionary["DTXcode"] as? String
            self.xcodeBuild = infoDictionary["DTXcodeBuild"] as? String
        }

        if let appStoreReceiptURL = environment.appStoreReceiptURL, let _ = try? Data(contentsOf: appStoreReceiptURL) {
            self.hasAppStoreReceipt = true
        }

        self.isDebugBuild = environment.isDebugBuild

        self.sdkVersion = environment.sdkVersion

        self.sdkProgrammingLanguage = "Swift"
        self.sdkAuthorName = "Apptentive, Inc."
        self.sdkPlatform = "Apple"

        self.sdkDistributionName = environment.distributionName
        self.sdkDistributionVersion = environment.distributionVersion
    }
}
