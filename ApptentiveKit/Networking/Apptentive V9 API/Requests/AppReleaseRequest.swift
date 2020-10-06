//
//  AppReleaseRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct AppReleaseRequest: Codable, Equatable {
    let sdkVersion: String
    let sdkProgrammingLanguage: String
    let sdkAuthorName: String
    let sdkPlatform: String
    let sdkDistributionName: String?
    let sdkDistributionVersion: String?
    let type: String
    let bundleIdentifier: String?
    let version: String?
    let build: String?
    let hasAppStoreReceipt: Bool
    let isDebugBuild: Bool
    let isOverridingStyles: Bool
    let compiler: String?
    let platformBuild: String?
    let platformName: String?
    let platformVersion: String?
    let sdkBuild: String?
    let sdkName: String?
    let xcode: String?
    let xcodeBuild: String?

    init(appRelease: AppRelease) {
        self.sdkVersion = appRelease.sdkVersion
        self.sdkProgrammingLanguage = appRelease.sdkProgrammingLanguage
        self.sdkAuthorName = appRelease.sdkAuthorName
        self.sdkPlatform = appRelease.sdkPlatform
        self.sdkDistributionName = appRelease.sdkDistributionName
        self.sdkDistributionVersion = appRelease.sdkDistributionVersion
        self.type = appRelease.type
        self.bundleIdentifier = appRelease.bundleIdentifier
        self.version = appRelease.version
        self.build = appRelease.build
        self.hasAppStoreReceipt = appRelease.hasAppStoreReceipt
        self.isDebugBuild = appRelease.isDebugBuild
        self.isOverridingStyles = appRelease.isOverridingStyles
        self.compiler = appRelease.compiler
        self.platformBuild = appRelease.platformBuild
        self.platformName = appRelease.platformName
        self.platformVersion = appRelease.platformVersion
        self.sdkBuild = appRelease.sdkBuild
        self.sdkName = appRelease.sdkName
        self.xcode = appRelease.xcode
        self.xcodeBuild = appRelease.xcodeBuild
    }

    enum CodingKeys: String, CodingKey {
        case sdkVersion = "sdk_version"
        case sdkProgrammingLanguage = "sdk_programming_language"
        case sdkAuthorName = "sdk_author_name"
        case sdkPlatform = "sdk_platform"
        case sdkDistributionName = "sdk_distribution"
        case sdkDistributionVersion = "sdk_distribution_version"
        case type
        case bundleIdentifier = "cf_bundle_identifier"
        case version = "cf_bundle_short_version_string"
        case build = "cf_bundle_version"
        case hasAppStoreReceipt = "app_store_receipt"
        case isDebugBuild = "debug"
        case isOverridingStyles = "overriding_styles"
        case compiler = "dt_compiler"
        case platformBuild = "dt_platform_build"
        case platformName = "dt_platform_name"
        case platformVersion = "dt_platform_version"
        case sdkBuild = "dt_sdk_build"
        case sdkName = "dt_sdk_name"
        case xcode = "dt_xcode"
        case xcodeBuild = "dt_xcode_build"
    }
}
