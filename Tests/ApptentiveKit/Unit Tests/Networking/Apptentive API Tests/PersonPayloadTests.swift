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
    var testPayload: Payload!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
        self.jsonDecoder.dateDecodingStrategy = .secondsSince1970

        var person = Person()

        person.name = "Testy McTestface"
        person.emailAddress = "test@example.com"
        person.mParticleID = "abc123"

        person.customData["string"] = "foo"
        person.customData["number"] = 42
        person.customData["bool"] = true

        self.testPayload = Payload(wrapping: person)

        super.setUp()
    }

    func testSerialization() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(self.testPayload, decodedPayload)
    }

    func testEncoding() throws {
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
            between: self.testPayload.jsonObject, and: expectedEncodedContent,
            comparisons: [
                "name",
                "email",
                "mparticle_id",
                "custom_data",
                "label",
            ])
    }
}
