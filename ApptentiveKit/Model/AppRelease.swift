//
//  AppRelease.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct AppRelease: Equatable, Codable {
    var type: String = "ios"
    var bundleIdentifier: String?
    var version: Version? {
        didSet {
            if version ?? 0 > oldValue ?? 0 {
                isUpdatedVersion = true
            }
        }
    }
    var build: Version? {
        didSet {
            if build ?? 0 > oldValue ?? 0 {
                isUpdatedBuild = true
            }
        }
    }
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
    var installTime: Date = Date()
    var versionInstallTime: Date = Date()
    var buildInstallTime: Date = Date()
    var sdkVersion: Version
    var sdkProgrammingLanguage: String
    var sdkAuthorName: String
    var sdkPlatform: String
    var sdkDistributionName: String?
    var sdkDistributionVersion: Version?

    init(environment: AppEnvironment) {
        if let infoDictionary = environment.infoDictionary {
            self.bundleIdentifier = infoDictionary["CFBundleIdentifier"] as? String

            if let versionString = infoDictionary["CFBundleShortVersionString"] as? String {
                self.version = Version(string: versionString)
            }

            if let buildString = infoDictionary["CFBundleVersion"] as? String {
                self.build = Version(string: buildString)
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

    mutating func merge(with newer: AppRelease) {
        self.bundleIdentifier = newer.bundleIdentifier
        self.version = newer.version
        self.build = newer.build
        self.hasAppStoreReceipt = newer.hasAppStoreReceipt
        self.isDebugBuild = newer.isDebugBuild
        self.isOverridingStyles = newer.isOverridingStyles
        self.compiler = newer.compiler
        self.platformBuild = newer.platformBuild
        self.platformName = newer.platformName
        self.platformVersion = newer.platformVersion
        self.sdkBuild = newer.sdkBuild
        self.sdkName = newer.sdkName
        self.xcode = newer.xcode
        self.xcodeBuild = newer.xcodeBuild

        self.sdkVersion = newer.sdkVersion
        self.sdkProgrammingLanguage = newer.sdkProgrammingLanguage
        self.sdkAuthorName = newer.sdkAuthorName
        self.sdkPlatform = newer.sdkPlatform
        self.sdkDistributionName = newer.sdkDistributionName
        self.sdkDistributionVersion = newer.sdkDistributionVersion
    }
}

// For testing only
extension AppRelease {
    mutating func bumpVersion() {
        self.version = Version(major: (version?.major ?? 0) + 1)
    }

    mutating func bumpBuild() {
        self.build = Version(major: (build?.major ?? 0) + 1)
    }
}
