//
//  AConversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/9/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct AConversation: Decodable {
    struct ConversationCredentials: Equatable, Codable {
        let token: String
        let id: String
    }

    var appCredentials: Apptentive.AppCredentials?
    var conversationCredentials: ConversationCredentials?
    var appRelease: AppRelease
    var person: Person
    var device: ADevice
    var codePoints: EngagementMetrics
    var interactions: EngagementMetrics
    var random: Random
}

struct ADevice: Decodable {
    var uuid: UUID?
    var osName: String?
    var osVersion: Version?
    var osBuild: Version?
    var hardware: String?
    var carrier: String?
    var contentSizeCategory: String?
    var localeRaw: String?
    var localeCountryCode: String?
    var localeLanguageCode: String?
    var utcOffset: Int?
    var integrationConfiguration = [String: [String: String]]()
    var advertisingIdentifier: UUID?
    var customData = CustomData()

    func currentDevice(with environment: DeviceEnvironment) -> Device {
        var device = Device(environment: environment)

        device.uuid = self.uuid
        device.osName = self.osName
        device.osVersion = self.osVersion
        device.osBuild = self.osBuild
        device.hardware = self.hardware
        device.carrier = self.carrier
        device.contentSizeCategory = self.contentSizeCategory
        device.localeRaw = self.localeRaw
        device.localeCountryCode = self.localeCountryCode
        device.localeLanguageCode = self.localeLanguageCode
        device.utcOffset = self.utcOffset
        device.advertisingIdentifier = self.advertisingIdentifier
        device.customData = self.customData

        device.integrationConfiguration["apptentive_push"] = self.integrationConfiguration["apptentive_push"]?["token"]
            .flatMap { Data(hexString: $0) }
            .flatMap { ["token": $0] }

        return device
    }
}
