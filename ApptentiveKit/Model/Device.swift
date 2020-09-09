//
//  Device.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Device {
    var uuid: UUID?
    var osName: String?
    var osVersion: String?
    var osBuild: String?
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

    init(environment: DeviceEnvironment) {
        self.uuid = environment.identifierForVendor
        self.osName = environment.osName
        self.osVersion = environment.osVersion

        self.osBuild = environment.osBuild
        self.hardware = environment.hardware
        self.carrier = environment.carrier

        self.contentSizeCategory = environment.contentSizeCategory.rawValue
        self.localeRaw = environment.localeIdentifier
        self.localeCountryCode = environment.localeRegionCode
        self.localeLanguageCode = environment.preferredLocalization

        self.utcOffset = environment.timeZoneSecondsFromGMT
    }
}
