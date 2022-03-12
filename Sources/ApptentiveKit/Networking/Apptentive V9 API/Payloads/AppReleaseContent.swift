//
//  AppReleaseContents.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/3/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct AppReleaseContent: Equatable, Codable, PayloadEncodable {
    var type: String
    var bundleIdentifier: String?
    var version: String?
    var build: String?
    var appStoreReceipt: AppStoreReceipt
    var isDebugBuild: Bool
    var isOverridingStyles: Bool
    var deploymentTarget: String?
    var compiler: String?
    var platformBuild: String?
    var platformName: String?
    var platformVersion: String?
    var sdkBuild: String?
    var sdkName: String?
    var xcode: String?
    var xcodeBuild: String?
    var sdkVersion: String
    var sdkProgrammingLanguage: String
    var sdkAuthorName: String
    var sdkPlatform: String
    var sdkDistributionName: String?
    var sdkDistributionVersion: String?

    init(with appRelease: AppRelease) {
        self.type = appRelease.type
        self.bundleIdentifier = appRelease.bundleIdentifier
        self.version = appRelease.version?.versionString
        self.build = appRelease.build?.versionString
        self.appStoreReceipt = AppStoreReceipt(hasReceipt: appRelease.hasAppStoreReceipt)
        self.isDebugBuild = appRelease.isDebugBuild
        self.isOverridingStyles = appRelease.isOverridingStyles
        self.deploymentTarget = appRelease.deploymentTarget
        self.compiler = appRelease.compiler
        self.platformBuild = appRelease.platformBuild
        self.platformName = appRelease.platformName
        self.platformVersion = appRelease.platformVersion
        self.sdkBuild = appRelease.sdkBuild
        self.sdkName = appRelease.sdkName
        self.xcode = appRelease.xcode
        self.xcodeBuild = appRelease.xcodeBuild
        self.sdkVersion = appRelease.sdkVersion.versionString
        self.sdkProgrammingLanguage = appRelease.sdkProgrammingLanguage
        self.sdkAuthorName = appRelease.sdkAuthorName
        self.sdkPlatform = appRelease.sdkPlatform
        self.sdkDistributionName = appRelease.sdkDistributionName
        self.sdkDistributionVersion = appRelease.sdkDistributionVersion?.versionString
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.type, forKey: .type)
        try container.encode(self.bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.build, forKey: .build)
        try container.encode(self.appStoreReceipt, forKey: .appStoreReceipt)
        try container.encode(self.isDebugBuild, forKey: .isDebugBuild)
        try container.encode(self.isOverridingStyles, forKey: .isOverridingStyles)
        try container.encode(self.deploymentTarget, forKey: .deploymentTarget)
        try container.encode(self.compiler, forKey: .compiler)
        try container.encode(self.platformBuild, forKey: .platformBuild)
        try container.encode(self.platformName, forKey: .platformName)
        try container.encode(self.platformVersion, forKey: .platformVersion)
        try container.encode(self.sdkBuild, forKey: .sdkBuild)
        try container.encode(self.sdkName, forKey: .sdkName)
        try container.encode(self.xcode, forKey: .xcode)
        try container.encode(self.xcodeBuild, forKey: .xcodeBuild)
        try container.encode(self.sdkVersion, forKey: .sdkVersion)
        try container.encode(self.sdkProgrammingLanguage, forKey: .sdkProgrammingLanguage)
        try container.encode(self.sdkAuthorName, forKey: .sdkAuthorName)
        try container.encode(self.sdkPlatform, forKey: .sdkPlatform)
        try container.encode(self.sdkDistributionName, forKey: .sdkDistributionName)
        try container.encode(self.sdkDistributionVersion, forKey: .sdkDistributionVersion)
    }

    enum CodingKeys: String, CodingKey {
        case type
        case bundleIdentifier = "cf_bundle_identifier"
        case version = "cf_bundle_short_version_string"
        case build = "cf_bundle_version"
        case appStoreReceipt = "app_store_receipt"
        case isDebugBuild = "debug"
        case isOverridingStyles = "overriding_styles"
        case deploymentTarget = "deployment_target"
        case compiler = "dt_compiler"
        case platformBuild = "dt_platform_build"
        case platformName = "dt_platform_name"
        case platformVersion = "dt_platform_version"
        case sdkBuild = "dt_sdk_build"
        case sdkName = "dt_sdk_name"
        case xcode = "dt_xcode"
        case xcodeBuild = "dt_xcode_build"
        case sdkVersion = "sdk_version"
        case sdkProgrammingLanguage = "sdk_programming_language"
        case sdkAuthorName = "sdk_author_name"
        case sdkPlatform = "sdk_platform"
        case sdkDistributionVersion = "sdk_distribution_version"
        case sdkDistributionName = "sdk_distribution"
    }

    struct AppStoreReceipt: Equatable, Codable {
        let hasReceipt: Bool

        enum CodingKeys: String, CodingKey {
            case hasReceipt = "has_receipt"
        }
    }
}
