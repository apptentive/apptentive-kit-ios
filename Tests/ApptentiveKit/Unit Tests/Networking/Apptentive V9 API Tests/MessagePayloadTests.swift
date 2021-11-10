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

        guard case let PayloadContents.message(decodedContents) = decodedMessagePayloadJSON.contents else {
            return XCTFail("Not a Message payload")
        }

        XCTAssertEqual(decodedContents.body, "Test Message")
        XCTAssertEqual(decodedContents.isAutomated, false)
        XCTAssertEqual(decodedContents.isHidden, true)

        XCTAssertEqual(decodedContents.customData["string"] as? String, "foo")
        XCTAssertEqual(decodedContents.customData["number"] as? Int, 42)
        XCTAssertEqual(decodedContents.customData["bool"] as? Bool, true)
    }

    func testMessageAttachments() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()
        let data2 = image2.jpegData(compressionQuality: 0.5)

        let attachment1 = Message.Attachment(mediaType: "image/png", filename: "logo", url: nil, data: data1)
        let attachment2 = Message.Attachment(mediaType: "image/jpeg", filename: "dog", url: nil, data: data2)

        let message = Message(body: "Test Attachments", attachments: [attachment1, attachment2], isHidden: true, isAutomated: false)

        let messagePayload = Payload(wrapping: message)

        let encodedMessagePayload = try jsonEncoder.encode(messagePayload)

        let expectedJSONString = """
            {
                "automated": false,
                "body": "Test Attachments",
                "hidden": true,
                "nonce": "abc123",
                "client_created_at": 1600904569,
                "client_created_at_utc_offset": 0
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

        guard case let PayloadContents.message(decodedContents) = decodedMessagePayloadJSON.contents else {
            return XCTFail("Not a Message payload")
        }

        XCTAssertEqual(decodedContents.body, "Test Attachments")
        XCTAssertEqual(decodedContents.isAutomated, false)
        XCTAssertEqual(decodedContents.isHidden, true)

        guard case let PayloadContents.message(originalContents) = messagePayload.contents else {
            return XCTFail("Not a message payload")
        }

        XCTAssertEqual(originalContents.attachmentBodyParts.count, 2)

        XCTAssertEqual(originalContents.attachmentBodyParts.first?.contentType, "image/png")
        XCTAssertEqual(originalContents.attachmentBodyParts.last?.contentType, "image/jpeg")

        XCTAssertEqual(originalContents.attachmentBodyParts.first?.contentDisposition, "form-data; name=\"file[]\"; filename=\"logo\"")
        XCTAssertEqual(originalContents.attachmentBodyParts.last?.contentDisposition, "form-data; name=\"file[]\"; filename=\"dog\"")

        XCTAssertEqual(try originalContents.attachmentBodyParts.first?.content(using: jsonEncoder), data1)
        XCTAssertEqual(try originalContents.attachmentBodyParts.last?.content(using: jsonEncoder), data2)
    }
}
