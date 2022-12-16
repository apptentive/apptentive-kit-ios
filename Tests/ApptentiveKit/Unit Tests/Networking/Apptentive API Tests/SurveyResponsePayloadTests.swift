//
//  SurveyResponsePayloadTests.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SurveyResponsePayloadTests: XCTestCase {
    var testPayload: Payload!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
        self.jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let surveyResponse = SurveyResponse(
            surveyID: "abc123",
            questionResponses: [
                "1": .answered([
                    .freeform("foobar")
                ]),
                "2": .answered([
                    .choice("abc123"),
                    .choice("def456"),
                ]),
                "3": .answered([
                    .range(3)
                ]),
                "4": .answered([
                    .choice("abc123"),
                    .other("def456", "barfoo"),
                ]),
            ])

        self.testPayload = Payload(wrapping: surveyResponse)

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
                "response": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "answers": {
                        "1": {
                            "state": "answered",
                            "value": [
                                {
                                    "value": "foobar"
                                }
                            ]
                        },
                        "2": {
                            "state": "answered",
                            "value": [
                                {
                                    "id": "abc123"
                                },
                                {
                                    "id": "def456"
                                }
                            ]
                        },
                        "3": {
                            "state": "answered",
                            "value": [
                                {
                                    "value": 3
                                }
                            ]
                        },
                        "4": {
                            "state": "answered",
                            "value": [
                                {
                                    "id": "abc123"
                                },
                                {
                                    "id": "def456",
                                    "value": "barfoo"
                                }
                            ]
                        }
                    }
                }
            }
            """

        try checkPayloadEquivalence(between: self.testPayload.jsonObject, and: expectedEncodedContent, comparisons: ["answers"])
    }
}
