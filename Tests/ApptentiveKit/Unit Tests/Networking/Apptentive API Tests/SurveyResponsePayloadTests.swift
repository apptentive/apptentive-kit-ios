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
    var surveyResponse: SurveyResponse!
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

        self.surveyResponse = SurveyResponse(
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

        super.setUp()
    }

    func testSerialization() throws {
        let testPayload = try Payload(wrapping: self.surveyResponse, with: self.payloadContext)

        let encodedPayloadData = try self.propertyListEncoder.encode(testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(testPayload, decodedPayload)
    }

    func testEncoding() throws {
        let testPayload = try Payload(wrapping: self.surveyResponse, with: self.payloadContext)

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

        try checkPayloadEquivalence(between: testPayload.bodyData!, and: expectedEncodedContent, comparisons: ["answers"])

        try checkRequestHeading(for: testPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "surveys/abc123/responses")
    }

    func testEncryptedEncoding() throws {
        let encryptedTestPayload = try Payload(wrapping: self.surveyResponse, with: self.encryptedPayloadContext)

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

        try checkEncryptedPayloadEquivalence(between: encryptedTestPayload.bodyData!, and: expectedEncodedContent, comparisons: ["answers"], encryptionKey: self.encryptionKey)

        try checkEncryptedRequestHeading(for: encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "surveys/abc123/responses")
    }
}
