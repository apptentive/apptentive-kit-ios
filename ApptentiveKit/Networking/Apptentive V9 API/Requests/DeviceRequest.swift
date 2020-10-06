//
//  DeviceRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

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
