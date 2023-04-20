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
    var device: Device!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder.apptentive
    let jsonDecoder = JSONDecoder.apptentive
    var payloadContext: Payload.Context!

    let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
    var encryptedPayloadContext: Payload.Context!

    override func setUpWithError() throws {
        self.payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
        self.encryptedPayloadContext = Payload.Context(tag: "abc123", credentials: .embedded(id: "abc"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "123"))
        let environment = MockEnvironment()

        self.device = Device(environment: environment)

        self.device.customData["string"] = "foo"
        self.device.customData["number"] = 42
        self.device.customData["bool"] = true

        self.device.remoteNotificationDeviceToken = Data(hexString: "80e17e3c13928e3a77aea742c7f94bd0966ae227b0f3a55ae6fc0a5e992f922b31e44f163ab2daeaa8df0048dc4744a4257b0c7b2d42a8570a3efc84f7c7797d50658f1a9a9b5936cbf87047c30a7057")

        super.setUp()
    }

    func testSerialization() throws {
        let testPayload = try Payload(wrapping: self.device, with: self.payloadContext)
        let encodedPayloadData = try self.propertyListEncoder.encode(testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(testPayload, decodedPayload)
    }

    func testEncoding() throws {
        let testPayload = try Payload(wrapping: self.device, with: self.payloadContext)
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
                    "apptentive_push": {
                        "token": "80e17e3c13928e3a77aea742c7f94bd0966ae227b0f3a55ae6fc0a5e992f922b31e44f163ab2daeaa8df0048dc4744a4257b0c7b2d42a8570a3efc84f7c7797d50658f1a9a9b5936cbf87047c30a7057"
                    },
                },
                "locale_country_code": "US",
                "os_build": "1",
                "client_created_at_utc_offset": -28800,
                "locale_raw": "en_US",
                "os_version": "12.0",
                "hardware": "iPhone0,0",
                "carrier": null
              }
            }
            """

        try checkPayloadEquivalence(
            between: testPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "uuid",
                "content_size_category",
                "os_name",
                "custom_data",
                "advertiser_id",
                "locale_language_code",
                "integration_config",
                "locale_country_code",
                "os_build",
                "utc_offset",
                "locale_raw",
                "os_version",
                "hardware",
                "carrier",
            ])

        try checkRequestHeading(for: testPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "device")
    }

    func testEncryptedEncoding() throws {
        let encryptedTestPayload = try Payload(wrapping: self.device, with: self.encryptedPayloadContext)

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
                    "apptentive_push": {
                        "token": "80e17e3c13928e3a77aea742c7f94bd0966ae227b0f3a55ae6fc0a5e992f922b31e44f163ab2daeaa8df0048dc4744a4257b0c7b2d42a8570a3efc84f7c7797d50658f1a9a9b5936cbf87047c30a7057"
                    },
                },
                "locale_country_code": "US",
                "os_build": "1",
                "client_created_at_utc_offset": -28800,
                "locale_raw": "en_US",
                "os_version": "12.0",
                "hardware": "iPhone0,0",
                "carrier": null
              }
            }
            """

        try checkEncryptedPayloadEquivalence(
            between: encryptedTestPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "uuid",
                "content_size_category",
                "os_name",
                "custom_data",
                "advertiser_id",
                "locale_language_code",
                "integration_config",
                "locale_country_code",
                "os_build",
                "utc_offset",
                "locale_raw",
                "os_version",
                "hardware",
                "carrier",
            ], encryptionKey: self.encryptionKey)

        try checkEncryptedRequestHeading(for: encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "device")
    }
}
