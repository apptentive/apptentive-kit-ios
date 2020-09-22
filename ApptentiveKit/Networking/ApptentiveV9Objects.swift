//
//  ApptentiveV9Objects.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/12/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ConversationRequest: Codable, Equatable {
    init(conversation: Conversation) {
        self.appRelease = AppReleaseRequest(appRelease: conversation.appRelease)
        self.device = DeviceRequest(device: conversation.device)
        self.person = PersonRequest(person: conversation.person)
    }

    let appRelease: AppReleaseRequest
    let person: PersonRequest
    let device: DeviceRequest

    enum CodingKeys: String, CodingKey {
        case appRelease = "app_release"
        case person
        case device
    }
}

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

struct PersonRequest: Codable, Equatable {
    let name: String?
    let emailAddress: String?
    let mParticleID: String?
    let customData: CustomData

    init(person: Person) {
        self.name = person.name
        self.emailAddress = person.emailAddress
        self.mParticleID = person.mParticleID
        self.customData = person.customData
    }

    enum CodingKeys: String, CodingKey {
        case name = "name"
        case emailAddress = "email"
        case mParticleID = "mparticle_id"
        case customData = "custom_data"
    }
}

struct DeviceRequest: Codable, Equatable {
    let uuid: UUID?
    let osName: String?
    let osVersion: String?
    let osBuild: String?
    let hardware: String?
    let carrier: String?
    let contentSizeCategory: String?
    let localeRaw: String?
    let localeCountryCode: String?
    let localeLanguageCode: String?
    let utcOffset: Int?
    let integrationConfiguration: [String: [String: String]]?
    let advertisingIdentifier: UUID?
    let customData: CustomData

    init(device: Device) {
        self.uuid = device.uuid
        self.osName = device.osName
        self.osVersion = device.osVersion
        self.osBuild = device.osBuild
        self.hardware = device.hardware
        self.carrier = device.carrier
        self.contentSizeCategory = device.contentSizeCategory
        self.localeRaw = device.localeRaw
        self.localeCountryCode = device.localeCountryCode
        self.localeLanguageCode = device.localeLanguageCode
        self.utcOffset = device.utcOffset
        self.integrationConfiguration = device.integrationConfiguration
        self.advertisingIdentifier = device.advertisingIdentifier
        self.customData = device.customData
    }

    enum CodingKeys: String, CodingKey {
        case uuid = "uuid"
        case osName = "os_name"
        case osVersion = "os_version"
        case osBuild = "os_build"
        case hardware = "hardware"
        case carrier = "carrier"
        case contentSizeCategory = "content_size_category"
        case localeRaw = "locale_raw"
        case localeCountryCode = "locale_country_code"
        case localeLanguageCode = "locale_language_code"
        case utcOffset = "utc_offset"
        case integrationConfiguration = "integration_config"
        case advertisingIdentifier = "advertiser_id"
        case customData = "custom_data"
    }
}

struct ConversationResponse: Codable, Equatable {
    let token: String
    let id: String
    let deviceID: String?
    let personID: String

    private enum CodingKeys: String, CodingKey {
        case token = "token"
        case id
        case deviceID = "device_id"
        case personID = "person_id"
    }
}
