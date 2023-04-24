//
//  PersonPayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/4/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class PersonPayloadTests: XCTestCase {
    var person: Person!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder.apptentive
    let jsonDecoder = JSONDecoder.apptentive
    var payloadContext: Payload.Context!

    let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
    var encryptedPayloadContext: Payload.Context!
    var encryptedTestPayload: Payload!

    override func setUpWithError() throws {
        self.payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
        self.encryptedPayloadContext = Payload.Context(tag: "abc123", credentials: .embedded(id: "abc"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "123"))

        self.person = Person()

        self.person.name = "Testy McTestface"
        self.person.emailAddress = "test@example.com"
        self.person.mParticleID = "abc123"

        self.person.customData["string"] = "foo"
        self.person.customData["number"] = 42
        self.person.customData["bool"] = true

        super.setUp()
    }

    func testSerialization() throws {
        let testPayload = try Payload(wrapping: self.person, with: self.payloadContext)
        let encodedPayloadData = try self.propertyListEncoder.encode(testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(testPayload, decodedPayload)
    }

    func testEncoding() throws {
        let testPayload = try Payload(wrapping: self.person, with: self.payloadContext)

        let expectedEncodedContent = """
            {
                "person": {
                    "name": "Testy McTestface",
                    "email": "test@example.com",
                    "mparticle_id": "abc123",
                    "custom_data": {
                        "string": "foo",
                        "number": 42,
                        "bool": true
                    },
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                }
            }
            """

        try checkPayloadEquivalence(
            between: testPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "name",
                "email",
                "mparticle_id",
                "custom_data",
                "label",
            ])

        try checkRequestHeading(for: testPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "person")
    }

    func testEncryptedEncoding() throws {
        let encryptedTestPayload = try Payload(wrapping: self.person, with: self.encryptedPayloadContext)

        let expectedEncodedContent = """
            {
                "person": {
                    "name": "Testy McTestface",
                    "email": "test@example.com",
                    "mparticle_id": "abc123",
                    "custom_data": {
                        "string": "foo",
                        "number": 42,
                        "bool": true
                    },
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                }
            }
            """

        try checkEncryptedPayloadEquivalence(
            between: encryptedTestPayload.bodyData!, and: expectedEncodedContent,
            comparisons: [
                "name",
                "email",
                "mparticle_id",
                "custom_data",
                "label",
            ], encryptionKey: self.encryptionKey)

        try checkEncryptedRequestHeading(for: encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .put, expectedPathSuffix: "person")
    }
}
