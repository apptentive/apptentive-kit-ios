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
    func testPersonEncoding() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        var person = Person()

        person.name = "Testy McTestface"
        person.emailAddress = "test@example.com"
        person.mParticleID = "abc123"

        person.customData["string"] = "foo"
        person.customData["number"] = 42
        person.customData["bool"] = true

        let personPayload = Payload(wrapping: person)

        let encodedPersonPayload = try jsonEncoder.encode(personPayload)

        let expectedJSONString = """
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
                    "label": "local#app#Foo bar"
                }
            }
            """

        let encodedExpectedJSON = expectedJSONString.data(using: .utf8)!

        let decodedExpectedJSON = try jsonDecoder.decode(Payload.self, from: encodedExpectedJSON)
        let decodedPersonPayloadJSON = try jsonDecoder.decode(Payload.self, from: encodedPersonPayload)

        XCTAssertNotNil(decodedPersonPayloadJSON.nonce)
        XCTAssertNotNil(decodedPersonPayloadJSON.creationDate)
        XCTAssertNotNil(decodedPersonPayloadJSON.creationUTCOffset)

        XCTAssertEqual(decodedExpectedJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertGreaterThan(decodedPersonPayloadJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))

        guard case let PayloadContents.person(payload) = decodedPersonPayloadJSON.contents else {
            return XCTFail("Not a person payload")
        }

        XCTAssertEqual(payload.name, "Testy McTestface")
        XCTAssertEqual(payload.emailAddress, "test@example.com")
        XCTAssertEqual(payload.mParticleID, "abc123")
        XCTAssertEqual(payload.customData["string"] as? String, "foo")
        XCTAssertEqual(payload.customData["number"] as? Int, 42)
        XCTAssertEqual(payload.customData["bool"] as? Bool, true)
    }
}
