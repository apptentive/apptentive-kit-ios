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
    var testPayload: Payload!
    var attachmentTestPayload: Payload!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()

    override func setUp() {
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
        self.jsonDecoder.dateDecodingStrategy = .secondsSince1970

        var customData = CustomData()
        customData["string"] = "foo"
        customData["number"] = 42
        customData["bool"] = true

        let message = MessageList.Message(nonce: "draft", body: "Test Message", isHidden: true, status: .draft)

        self.testPayload = Payload(wrapping: message, customData: customData, attachmentURLProvider: MockAttachmentURLProviding())

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let messageWithAttachments = MessageList.Message(nonce: "draft", body: "Test Attachments", attachments: [attachment1, attachment2], isHidden: true, status: .draft)

        self.attachmentTestPayload = Payload(wrapping: messageWithAttachments, customData: nil, attachmentURLProvider: MockAttachmentURLProviding())

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

    func testEncodingWithAttachments() throws {
        let parts = self.attachmentTestPayload.bodyParts

        XCTAssertEqual(parts.count, 3)

        XCTAssertEqual(parts[0].contentType, "application/json;charset=UTF-8")
        XCTAssertEqual(parts[1].contentType, "image/png")
        XCTAssertEqual(parts[2].contentType, "image/jpeg")

        let content0Data = try parts[0].content(using: self.jsonEncoder)
        let actualDecodedContent = try jsonDecoder.decode(Payload.JSONObject.self, from: content0Data)

        guard case Payload.SpecializedJSONObject.message(let actualMessageContent) = actualDecodedContent.specializedJSONObject else {
            return XCTFail("Multipart first part is not message-related")
        }

        let expectedEncodedContent = """
            {
                "automated": false,
                "body": "Test Attachments",
                "hidden": true,
                "nonce": "abc123",
                "client_created_at": 1600904569,
                "client_created_at_utc_offset": 0
            }
            """.data(using: .utf8)!

        let expectedDecodedContent = try jsonDecoder.decode(Payload.JSONObject.self, from: expectedEncodedContent)
        guard case Payload.SpecializedJSONObject.message(let expectedMessageContent) = expectedDecodedContent.specializedJSONObject else {
            return XCTFail("Multipart ")
        }

        XCTAssertEqual(actualMessageContent, expectedMessageContent)

        try XCTAssertEqual(parts[1].content(using: self.jsonEncoder), self.attachmentTestPayload.attachments[0].content(using: self.jsonEncoder))
        try XCTAssertEqual(parts[2].content(using: self.jsonEncoder), self.attachmentTestPayload.attachments[1].content(using: self.jsonEncoder))
    }

    func testSerializationWithAttachments() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.attachmentTestPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(self.attachmentTestPayload, decodedPayload)
    }
}

class MockAttachmentURLProviding: AttachmentURLProviding {
    func url(for attachment: MessageList.Message.Attachment) -> URL? {
        return Bundle(for: type(of: self)).url(forResource: "dog", withExtension: "jpg")
    }
}
