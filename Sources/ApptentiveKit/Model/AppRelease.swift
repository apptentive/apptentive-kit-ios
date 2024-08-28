//
//  AppRelease.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object representing the state of an app when launched.
struct AppRelease: Equatable, Codable {

    /// The type of the app (e.g. "ios" or "android").
    var type: String = "ios"

    /// The bundle identifier for the app.
    var bundleIdentifier: String?

    /// The app's version (corresponding to the `CFBundleShortVersionString` entry in the app's `Info.plist` file).
    var version: Version? {
        didSet {
            if version ?? 0 > oldValue ?? 0 {
                isUpdatedVersion = true
            }
        }
    }

    /// The app's build (corresponding to the `CFBundleVersion` entry in the app's `Info.plist` file).
    var build: Version? {
        didSet {
            if build ?? 0 > oldValue ?? 0 {
                isUpdatedBuild = true
            }
        }
    }

    /// Whether an app store receipt URL is present in the app's `Info.plist` file.
    var hasAppStoreReceipt: Bool = false

    /// Whether the SDK was built in debug mode.
    var isDebugBuild: Bool = false

    /// Whether the app is overriding the default Apptentive styling.
    var isOverridingStyles: Bool = false

    /// The minimum OS version that the app can run on.
    var deploymentTarget: String?

    /// The compiler used to build the SDK.
    var compiler: String?

    /// The build of the platform used to build the SDK.
    var platformBuild: String?

    /// The name of the platform used to build the SDK.
    var platformName: String?

    /// The version of the platform used to build the SDK.
    var platformVersion: String?

    /// The build of the Xcode SDK used to build the SDK.
    var sdkBuild: String?

    /// The name of the Xcode SDK used to build the SDK.
    var sdkName: String?

    /// The name of the Xcode used to build the SDK.
    var xcode: String?

    /// The build of the Xcode used to build the SDK.
    var xcodeBuild: String?

    /// Whether the current version of the app is different from the version when the SDK was initially present.
    var isUpdatedVersion: Bool = false

    /// Whether the current build of the app is different from the build when the SDK was initially present.
    var isUpdatedBuild: Bool = false

    /// When the app was first run with the SDK present.
    var installTime: Date = Date()

    /// When the current version of the app was first run with the SDK present.
    var versionInstallTime: Date = Date()

    /// When the current build of the app was first run with the SDK present.
    var buildInstallTime: Date = Date()

    /// The version of the SDK.
    var sdkVersion: Version

    /// The programming language in which the SDK is written.
    var sdkProgrammingLanguage: String

    /// The name of the author of the SDK.
    var sdkAuthorName: String

    /// The platform for which the SDK is built.
    var sdkPlatform: String

    /// The name of the distribution including the SDK (e.g. "Source", or "React Native").
    var sdkDistributionName: String?

    /// The version of the distribution including the SDK.
    var sdkDistributionVersion: Version?

    /// Initializes a new app release with the specified environment.
    /// - Parameter dataProvider: The data provider used to set initial values.
    init(dataProvider: AppDataProviding) {
        self.bundleIdentifier = dataProvider.bundleIdentifier
        self.version = dataProvider.version
        self.build = dataProvider.build
        self.deploymentTarget = dataProvider.deploymentTarget
        self.compiler = dataProvider.compiler
        self.platformBuild = dataProvider.platformBuild
        self.platformName = dataProvider.platformName
        self.platformVersion = dataProvider.platformVersion
        self.sdkBuild = dataProvider.sdkBuild
        self.sdkName = dataProvider.sdkName
        self.xcode = dataProvider.xcode
        self.xcodeBuild = dataProvider.xcodeBuild

        if let appStoreReceiptURL = dataProvider.appStoreReceiptURL, let _ = try? Data(contentsOf: appStoreReceiptURL) {
            self.hasAppStoreReceipt = true
        }

        self.isDebugBuild = dataProvider.isDebugBuild

        self.sdkVersion = dataProvider.sdkVersion

        self.sdkProgrammingLanguage = "Swift"
        self.sdkAuthorName = "Apptentive, Inc."
        self.sdkPlatform = "iOS"
        self.isOverridingStyles = dataProvider.isOverridingStyles
        self.sdkDistributionName = dataProvider.distributionName
        self.sdkDistributionVersion = dataProvider.distributionVersion
    }

    /// Merges a newer app release object into the current one.
    /// - Parameter newer: The newer app release object.
    mutating func merge(with newer: AppRelease) {
        self.bundleIdentifier = newer.bundleIdentifier
        self.version = newer.version
        self.build = newer.build
        self.hasAppStoreReceipt = newer.hasAppStoreReceipt
        self.isDebugBuild = newer.isDebugBuild
        self.isOverridingStyles = newer.isOverridingStyles
        self.deploymentTarget = newer.deploymentTarget
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

// For testing only.
extension AppRelease {
    mutating func bumpVersion() {
        self.version = Version(major: (version?.major ?? 0) + 1)
    }

    mutating func bumpBuild() {
        self.build = Version(major: (build?.major ?? 0) + 1)
    }
}
