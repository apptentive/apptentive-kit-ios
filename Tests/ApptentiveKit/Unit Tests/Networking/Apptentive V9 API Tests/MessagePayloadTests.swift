//
//  MessagePayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class MessagePayloadTests: XCTestCase {
    func testMessageEncoding() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        var message = Message(body: "Test Message", isHidden: true, sentDate: Date())

        message.customData["string"] = "foo"
        message.customData["number"] = 42
        message.customData["bool"] = true

        let messagePayload = Payload(wrapping: message)

        let encodedMessagePayload = try jsonEncoder.encode(messagePayload)

        let expectedJSONString = """
            {
                "message": {
                    "custom_data": {
                        "string": "foo",
                        "number": 42,
                        "bool": true
                    },
                    "automated": false,
                    "hidden": true,
                    "body": "Test Message",
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0
                }
            }
            """

        let encodedExpectedJSON = expectedJSONString.data(using: .utf8)!

        let decodedExpectedJSON = try jsonDecoder.decode(Payload.self, from: encodedExpectedJSON)
        let decodedMessagePayloadJSON = try jsonDecoder.decode(Payload.self, from: encodedMessagePayload)

        XCTAssertNotNil(decodedMessagePayloadJSON.nonce)
        XCTAssertNotNil(decodedMessagePayloadJSON.creationDate)
        XCTAssertNotNil(decodedMessagePayloadJSON.creationUTCOffset)

        XCTAssertEqual(decodedExpectedJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertGreaterThan(decodedMessagePayloadJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))

        guard case let PayloadContents.message(payload) = decodedMessagePayloadJSON.contents else {
            return XCTFail("Not a Message payload")
        }

        XCTAssertEqual(payload.body, "Test Message")
        XCTAssertEqual(payload.isAutomated, false)
        XCTAssertEqual(payload.isHidden, true)

        XCTAssertEqual(payload.customData["string"] as? String, "foo")
        XCTAssertEqual(payload.customData["number"] as? Int, 42)
        XCTAssertEqual(payload.customData["bool"] as? Bool, true)
    }
}
