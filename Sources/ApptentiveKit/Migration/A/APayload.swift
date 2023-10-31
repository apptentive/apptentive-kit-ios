//
//  APayload.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/8/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct APayload: Decodable {
    let jsonObject: JSONObject
    let method: HTTPMethod
    let path: String
    let attachments: [Payload.Attachment]

    struct JSONObject: Decodable {
        let specializedJSONObject: Payload.SpecializedJSONObject
        let nonce: String
        let createdAt: Date
        let creationUTCOffset: Int
        let shouldStripContainer: Bool
        let sessionID: String?
        var filename: String? = nil

        init(from decoder: Decoder) throws {
            var nestedContainer: KeyedDecodingContainer<Payload.AllPossibleCodingKeys>

            let container = try decoder.container(keyedBy: Payload.JSONObject.PayloadTypeCodingKeys.self)

            if let containerKey = container.allKeys.first {
                switch containerKey {
                case .response:
                    self.specializedJSONObject = .surveyResponse(try container.decode(SurveyResponseContent.self, forKey: containerKey))

                case .event:
                    self.specializedJSONObject = .event(try container.decode(EventContent.self, forKey: containerKey))

                case .person:
                    self.specializedJSONObject = .person(try container.decode(PersonContent.self, forKey: containerKey))

                case .device:
                    self.specializedJSONObject = .device(try container.decode(ADeviceContent.self, forKey: containerKey).currentDeviceContent)

                case .appRelease:
                    self.specializedJSONObject = .appRelease(try container.decode(AppReleaseContent.self, forKey: containerKey))

                case .message:
                    self.specializedJSONObject = .message(try container.decode(MessageContent.self, forKey: containerKey))

                default:
                    apptentiveCriticalError("Unexpected container key for revision A payload data.")
                    self.specializedJSONObject = .logout
                }

                nestedContainer = try container.nestedContainer(keyedBy: Payload.AllPossibleCodingKeys.self, forKey: containerKey)

                self.shouldStripContainer = false
            } else {
                nestedContainer = try decoder.container(keyedBy: Payload.AllPossibleCodingKeys.self)

                self.specializedJSONObject = .message(try MessageContent.init(from: decoder))

                self.shouldStripContainer = true
            }

            self.nonce = try nestedContainer.decode(String.self, forKey: .nonce)
            self.createdAt = try nestedContainer.decode(Date.self, forKey: .createdAt)
            self.creationUTCOffset = try nestedContainer.decode(Int.self, forKey: .creationUTCOffset)
            self.sessionID = try nestedContainer.decodeIfPresent(String.self, forKey: .sessionID)
        }
    }
}

extension DeviceContent {
    init(
        uuid: UUID? = nil, osName: String? = nil, osVersion: String? = nil, osBuild: String? = nil, hardware: String? = nil, carrier: String? = nil, contentSizeCategory: String? = nil, localeRaw: String? = nil, localeCountryCode: String? = nil,
        localeLanguageCode: String? = nil, integrationConfiguration: [String: [String: Data]]? = nil, advertisingIdentifier: UUID? = nil, customData: CustomData
    ) {
        self.uuid = uuid
        self.osName = osName
        self.osVersion = osVersion
        self.osBuild = osBuild
        self.hardware = hardware
        self.carrier = carrier
        self.contentSizeCategory = contentSizeCategory
        self.localeRaw = localeRaw
        self.localeCountryCode = localeCountryCode
        self.localeLanguageCode = localeLanguageCode
        self.integrationConfiguration = integrationConfiguration
        self.advertisingIdentifier = advertisingIdentifier
        self.customData = customData
    }
}

struct ADeviceContent: Decodable {
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
    let integrationConfiguration: [String: [String: String]]?
    let advertisingIdentifier: UUID?
    let customData: CustomData

    var currentDeviceContent: DeviceContent {
        let currentIntegrationConfiguration = self.integrationConfiguration?["apptentive_push"]?["token"]
            .flatMap { Data(hexString: $0) }
            .flatMap { ["apptentive_push": ["token": $0]] }

        return DeviceContent(
            uuid: self.uuid,
            osName: self.osName,
            osVersion: self.osVersion,
            osBuild: self.osBuild,
            hardware: self.hardware,
            carrier: self.carrier,
            contentSizeCategory: self.contentSizeCategory,
            localeRaw: self.localeRaw,
            localeCountryCode: self.localeCountryCode,
            localeLanguageCode: self.localeLanguageCode,
            integrationConfiguration: currentIntegrationConfiguration,
            advertisingIdentifier: self.advertisingIdentifier,
            customData: self.customData)
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
