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
    var testPayload: Payload!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
        self.jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let environment = MockEnvironment()

        var device = Device(environment: environment)

        device.customData["string"] = "foo"
        device.customData["number"] = 42
        device.customData["bool"] = true

        self.testPayload = Payload(wrapping: device)

        super.setUp()
    }

    func testSerialization() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(self.testPayload, decodedPayload)
    }

    func testEncoding() throws {
        let actualEncodedContent = try jsonEncoder.encode(self.testPayload.jsonObject)
        let actualDecodedContent = try jsonDecoder.decode(Payload.JSONObject.self, from: actualEncodedContent)

        let expectedEncodedContent = """
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
                "os_build": "1",
                "client_created_at_utc_offset": -28800,
                "utc_offset": -25200,
                "locale_raw": "en_US",
                "os_version": "12.0",
                "hardware": "iPhone0,0",
                "carrier": null
              }
            }
            """.data(using: .utf8)!

        let expectedDecodedContent = try jsonDecoder.decode(Payload.JSONObject.self, from: expectedEncodedContent)

        XCTAssertNotNil(actualDecodedContent.nonce)
        XCTAssertNotNil(expectedDecodedContent.nonce)

        XCTAssertGreaterThan(actualDecodedContent.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertEqual(expectedDecodedContent.creationDate, Date(timeIntervalSince1970: 1_600_904_569))

        XCTAssertNotNil(actualDecodedContent.creationUTCOffset)
        XCTAssertNotNil(expectedDecodedContent.creationUTCOffset)

        XCTAssertEqual(expectedDecodedContent.specializedJSONObject, actualDecodedContent.specializedJSONObject)
    }
}
