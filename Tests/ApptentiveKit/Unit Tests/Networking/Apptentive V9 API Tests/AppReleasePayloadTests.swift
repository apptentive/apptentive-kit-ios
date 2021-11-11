//
//  AppReleasePayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/4/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class AppReleasePayloadTests: XCTestCase {
    var testPayload: Payload!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
        self.jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let environment = MockEnvironment()

        let appRelease = AppRelease(environment: environment)

        self.testPayload = Payload(wrapping: appRelease)

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
                          "app_release": {
                            "sdk_version": "0.0.0",
                            "dt_platform_version": "13.4",
                            "dt_platform_build": "17E218",
                            "cf_bundle_short_version_string": "0.0.0",
                            "sdk_platform": "iOS",
                            "client_created_at_utc_offset": -28800,
                            "cf_bundle_version": "1",
                            "app_store_receipt": {
                              "has_receipt": false
                            },
                            "sdk_programming_language": "Swift",
                            "client_created_at": 1600904569,
                            "dt_xcode_build": "11E703a",
                            "dt_xcode": "1160",
                            "nonce": "3EED102B-E0CA-4E8F-BAAA-8BBF9BD3C534",
                            "type": "ios",
                            "dt_platform_name": "iphonesimulator",
                            "overriding_styles": false,
                            "dt_sdk_name": "iphonesimulator13.4.internal",
                            "debug": true,
                            "sdk_author_name": "Apptentive, Inc.",
                            "dt_compiler": "com.apple.compilers.llvm.clang.1_0",
                            "dt_sdk_build": "17E218",
                            "sdk_distribution": null,
                            "sdk_distribution_version": null,
                            "cf_bundle_identifier": "com.apptentive.test",
                            "deployment_target": "12.1"
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
