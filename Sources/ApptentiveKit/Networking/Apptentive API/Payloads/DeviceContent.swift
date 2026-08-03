//
//  DeviceContent.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/3/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct DeviceContent: Equatable, Codable, PayloadEncodable {
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
    let integrationConfiguration: [String: [String: Data]]?
    let advertisingIdentifier: UUID?
    let customData: CustomData

    internal init(with device: Device) {
        self.uuid = device.uuid
        self.osName = device.osName
        self.osVersion = device.osVersion?.versionString
        self.osBuild = device.osBuild?.versionString
        self.hardware = device.hardware
        self.carrier = device.carrier
        self.contentSizeCategory = device.contentSizeCategory
        self.localeRaw = device.localeRaw
        self.localeCountryCode = device.localeCountryCode
        self.localeLanguageCode = device.localeLanguageCode
        self.integrationConfiguration = device.integrationConfiguration
        self.advertisingIdentifier = device.advertisingIdentifier
        self.customData = device.customData
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.uuid, forKey: .uuid)
        try container.encode(self.osName, forKey: .osName)
        try container.encode(self.osVersion, forKey: .osVersion)
        try container.encode(self.osBuild, forKey: .osBuild)
        try container.encode(self.hardware, forKey: .hardware)
        try container.encode(self.carrier, forKey: .carrier)
        try container.encode(self.contentSizeCategory, forKey: .contentSizeCategory)
        try container.encode(self.localeRaw, forKey: .localeRaw)
        try container.encode(self.localeCountryCode, forKey: .localeCountryCode)
        try container.encode(self.localeLanguageCode, forKey: .localeLanguageCode)
        try container.encode(self.integrationConfiguration, forKey: .integrationConfiguration)
        try container.encode(self.advertisingIdentifier, forKey: .advertisingIdentifier)
        try container.encode(self.customData, forKey: .customData)
    }

    func differs(from other: DeviceContent, includeCustomData: Bool = true) -> Bool {
        return self.uuid != other.uuid
            || self.osName != other.osName
            || self.osVersion != other.osVersion
            || self.osBuild != other.osBuild
            || self.hardware != other.hardware
            || self.carrier != other.carrier
            || self.contentSizeCategory != other.contentSizeCategory
            || self.localeRaw != other.localeRaw
            || self.localeCountryCode != other.localeCountryCode
            || self.localeLanguageCode != other.localeLanguageCode
            || self.integrationConfiguration != other.integrationConfiguration
            || self.advertisingIdentifier != other.advertisingIdentifier
            || (includeCustomData && self.customData != other.customData)
    }

    enum CodingKeys: String, CodingKey {
        case uuid
        case osName = "os_name"
        case osVersion = "os_version"
        case osBuild = "os_build"
        case hardware
        case carrier
        case contentSizeCategory = "content_size_category"
        case localeRaw = "locale_raw"
        case localeCountryCode = "locale_country_code"
        case localeLanguageCode = "locale_language_code"
        case integrationConfiguration = "integration_config"
        case advertisingIdentifier = "advertiser_id"
        case customData = "custom_data"
    }
}
