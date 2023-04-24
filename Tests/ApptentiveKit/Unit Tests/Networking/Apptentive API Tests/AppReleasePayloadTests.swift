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
    var appRelease: AppRelease!
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

        self.appRelease = AppRelease(environment: environment)

        super.setUp()
    }

    func testSerialization() throws {
        let testPayload = try Payload(wrapping: self.appRelease, with: self.payloadContext)

        let encodedPayloadData = try self.propertyListEncoder.encode(testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(testPayload, decodedPayload)
    }

    func testEncoding() throws {
        let testPayload = try Payload(wrapping: self.appRelease, with: self.payloadContext)

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
            """

        try checkPayloadEquivalence(
            between: testPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "sdk_version",
                "dt_platform_version",
                "dt_platform_build",
                "cf_bundle_short_version_string",
                "sdk_platform",
                "cf_bundle_version",
                "app_store_receipt",
                "sdk_programming_language",
                "dt_xcode_build",
                "dt_xcode",
                "type",
                "dt_platform_name",
                "overriding_styles",
                "dt_sdk_name",
                "debug",
                "sdk_author_name",
                "dt_compiler",
                "dt_sdk_build",
                "sdk_distribution",
                "sdk_distribution_version",
                "cf_bundle_identifier",
                "deployment_target",
            ])

        try checkRequestHeading(for: testPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "app_release")
    }

    func testEncryptedEncoding() throws {
        let encryptedTestPayload = try Payload(wrapping: self.appRelease, with: self.encryptedPayloadContext)

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
            """

        try checkEncryptedPayloadEquivalence(
            between: encryptedTestPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "sdk_version",
                "dt_platform_version",
                "dt_platform_build",
                "cf_bundle_short_version_string",
                "sdk_platform",
                "cf_bundle_version",
                "app_store_receipt",
                "sdk_programming_language",
                "dt_xcode_build",
                "dt_xcode",
                "type",
                "dt_platform_name",
                "overriding_styles",
                "dt_sdk_name",
                "debug",
                "sdk_author_name",
                "dt_compiler",
                "dt_sdk_build",
                "sdk_distribution",
                "sdk_distribution_version",
                "cf_bundle_identifier",
                "deployment_target",
            ], encryptionKey: self.encryptionKey)

        try checkEncryptedRequestHeading(for: encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "app_release")
    }
}
