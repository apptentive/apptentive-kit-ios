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

        let message = Message(body: "Test Message", isHidden: true, customData: customData, sentDate: Date())

        self.testPayload = Payload(wrapping: message)

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = Message.Attachment(mediaType: "image/png", filename: "logo", url: nil, data: data1)
        let attachment2 = Message.Attachment(mediaType: "image/jpeg", filename: "dog", url: nil, data: data2)

        let messageWithAttachments = Message(body: "Test Attachments", attachments: [attachment1, attachment2], isHidden: true, isAutomated: false)

        self.attachmentTestPayload = Payload(wrapping: messageWithAttachments)

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

        XCTAssertEqual(parts[0].contentType, "application/json")
        XCTAssertEqual(parts[1].contentType, "image/png")
        XCTAssertEqual(parts[2].contentType, "image/jpeg")

        XCTAssertEqual(parts[0].contentDisposition, "form-data; name=\"message\"")
        XCTAssertEqual(parts[1].contentDisposition, "form-data; name=\"file[]\"; filename=\"logo\"")
        XCTAssertEqual(parts[2].contentDisposition, "form-data; name=\"file[]\"; filename=\"dog\"")

        guard case HTTPBodyPart.BodyPartData.jsonEncoded(let content0Encodable) = parts[0].content else {
            return XCTFail("Multipart first part is not JSON")
        }

        guard let actualDecodedContent = content0Encodable as? Payload.JSONObject,
            case Payload.SpecializedJSONObject.message(let actualMessageContent) = actualDecodedContent.specializedJSONObject
        else {
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

        guard case HTTPBodyPart.BodyPartData.raw(let content1Data) = parts[1].content,
            case HTTPBodyPart.BodyPartData.raw(let content2Data) = parts[2].content
        else {
            return XCTFail("Attachment body parts are not raw data")
        }

        XCTAssertEqual(content1Data, self.attachmentTestPayload.attachments[0].data)
        XCTAssertEqual(content2Data, self.attachmentTestPayload.attachments[1].data)
    }

    func testSerializationWithAttachments() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.attachmentTestPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        XCTAssertEqual(self.attachmentTestPayload, decodedPayload)
    }
}
