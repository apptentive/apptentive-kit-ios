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
    func testSurveyResponseEncoding() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let surveyResponse = SurveyResponse(
            surveyID: "abc123",
            answers: [
                "1": [
                    .freeform("foobar")
                ],
                "2": [
                    .choice("abc123"),
                    .choice("def456"),
                ],
                "3": [
                    .range(3)
                ],
                "4": [
                    .choice("abc123"),
                    .other("def456", "barfoo"),
                ],
            ])

        let responsePayload = Payload(wrapping: surveyResponse)

        let encodedResponsePayload = try jsonEncoder.encode(responsePayload)

        let expectedJSONString = """
            {
                "response": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "answers": {
                        "1": [
                            {
                                "value": "foobar"
                            }
                        ],
                        "2": [
                            {
                                "id": "abc123"
                            },
                            {
                                "id": "def456"
                            }
                        ],
                        "3": [
                            {
                                "value": 3
                            }
                        ],
                        "4": [
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
            """

        let encodedExpectedJSON = expectedJSONString.data(using: .utf8)!

        let decodedExpectedJSON = try jsonDecoder.decode(Payload.self, from: encodedExpectedJSON)
        let decodedResponsePayloadJSON = try jsonDecoder.decode(Payload.self, from: encodedResponsePayload)

        XCTAssertEqual(decodedResponsePayloadJSON.contents, decodedExpectedJSON.contents)

        XCTAssertNotNil(decodedResponsePayloadJSON.nonce)
        XCTAssertNotNil(decodedResponsePayloadJSON.creationDate)
        XCTAssertNotNil(decodedResponsePayloadJSON.creationUTCOffset)

        XCTAssertEqual(decodedExpectedJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertGreaterThan(decodedResponsePayloadJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
    }
}
