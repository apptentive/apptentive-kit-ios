//
//  DevicePayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/4/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class DevicePayloadTests: XCTestCase {
    func testDeviceEncoding() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let environment = MockEnvironment()

        var device = Device(environment: environment)

        device.customData["string"] = "foo"
        device.customData["number"] = 42
        device.customData["bool"] = true

        let devicePayload = Payload(wrapping: device)

        let encodedDevicePayload = try jsonEncoder.encode(devicePayload)

        let expectedJSONString = """
            {
              "device": {
                "uuid": "A230943F-14C7-4C57-BEA2-39EFC51F284C",
                "client_created_at": 1600904569,
                "content_size_category": "UICTContentSizeCategoryM",
                "os_name": "iOS",
                "custom_data": {
                  "string": "foo",
                  "number": 42,
                  "bool": true
                },
                "nonce": "3C7C0FD3-EA78-4C00-AD01-529CBDC6C805",
                "advertiser_id": null,
                "locale_language_code": "en",
                "integration_config": {
                },
                "locale_country_code": "US",
                "os_build": "0.0.1",
                "client_created_at_utc_offset": -28800,
                "utc_offset": -25200,
                "locale_raw": "en_US",
                "os_version": "0.0.12",
                "hardware": "iPhone0,0",
                "carrier": null
              }
            }
            """

        let encodedExpectedJSON = expectedJSONString.data(using: .utf8)!

        let decodedExpectedJSON = try jsonDecoder.decode(Payload.self, from: encodedExpectedJSON)
        let decodedDevicePayloadJSON = try jsonDecoder.decode(Payload.self, from: encodedDevicePayload)

        XCTAssertNotNil(decodedDevicePayloadJSON.nonce)
        XCTAssertNotNil(decodedDevicePayloadJSON.creationDate)
        XCTAssertNotNil(decodedDevicePayloadJSON.creationUTCOffset)

        XCTAssertEqual(decodedExpectedJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertGreaterThan(decodedDevicePayloadJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))

        guard case let PayloadContents.device(payload) = decodedDevicePayloadJSON.contents else {
            return XCTFail("Not a device payload")
        }

        XCTAssertEqual(payload.uuid, environment.identifierForVendor)
        XCTAssertEqual(payload.osName, environment.osName)
        XCTAssertEqual(payload.osVersion, environment.osVersion.versionString)
        XCTAssertEqual(payload.osBuild, environment.osBuild.versionString)
        XCTAssertEqual(payload.hardware, environment.hardware)
        XCTAssertEqual(payload.carrier, environment.carrier)
        XCTAssertEqual(payload.contentSizeCategory, environment.contentSizeCategory.rawValue)
        XCTAssertEqual(payload.localeRaw, environment.localeIdentifier)
        XCTAssertEqual(payload.localeCountryCode, environment.localeRegionCode)
        XCTAssertEqual(payload.localeLanguageCode, environment.preferredLocalization)
        XCTAssertEqual(payload.utcOffset, environment.timeZoneSecondsFromGMT)

        XCTAssertEqual(payload.customData["string"] as? String, "foo")
        XCTAssertEqual(payload.customData["number"] as? Int, 42)
        XCTAssertEqual(payload.customData["bool"] as? Bool, true)
    }
}
