//
//  MessagePayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

struct MessagePayloadTests {
    var testPayload: Payload!
    var attachmentTestPayload: Payload!
    var data1: Data!
    var data2: Data!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder.apptentive
    let jsonDecoder = JSONDecoder.apptentive
    var payloadContext: Payload.Context!

    let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
    var encryptedPayloadContext: Payload.Context!
    var encryptedTestPayload: Payload!
    var encryptedAttachmentTestPayload: Payload!

    init() throws {
        self.payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
        self.encryptedPayloadContext = Payload.Context(tag: "abc123", credentials: .embedded(id: "abc"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "123"))

        var customData = CustomData()
        customData["string"] = "foo"
        customData["number"] = 42
        customData["bool"] = true

        let message = MessageList.Message(nonce: "draft", body: "Test Message", isHidden: true, status: .draft)

        self.testPayload = try Payload(wrapping: message, with: self.payloadContext, customData: customData, attachmentURLProvider: MockAttachmentURLProviding())
        self.encryptedTestPayload = try Payload(wrapping: message, with: self.encryptedPayloadContext, customData: customData, attachmentURLProvider: MockAttachmentURLProviding())

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!

        self.data1 = image1.pngData()!
        self.data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let messageWithAttachments = MessageList.Message(nonce: "draft", body: "Test Attachments", attachments: [attachment1, attachment2], isHidden: true, status: .draft)

        self.attachmentTestPayload = try Payload(wrapping: messageWithAttachments, with: self.payloadContext, customData: nil, attachmentURLProvider: MockAttachmentURLProviding())
        self.encryptedAttachmentTestPayload = try Payload(wrapping: messageWithAttachments, with: self.encryptedPayloadContext, customData: nil, attachmentURLProvider: MockAttachmentURLProviding())
    }

    @Test func testSerialization() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        #expect(self.testPayload == decodedPayload)
    }

    @Test func testSerializationWithAttachments() throws {
        let encodedPayloadData = try self.propertyListEncoder.encode(self.attachmentTestPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        #expect(self.attachmentTestPayload == decodedPayload)
    }

    @Test func testEncoding() throws {
        let boundary = self.testPayload.contentType?.components(separatedBy: ";")[1].components(separatedBy: "=")[1]

        let parts = try ApptentiveAPITests.parseMultipartBody(self.testPayload.bodyData!, boundary: boundary!)

        #expect(parts.count == 1)

        #expect(parts[0].headers["Content-Type"] == "application/json;charset=UTF-8")

        let content0Data = parts[0].content

        let expectedAttachmentEncodedContent = """
            {
                "automated": false,
                "body": "Test Message",
                "hidden": true,
                "nonce": "abc123",
                "client_created_at": 1600904569,
                "client_created_at_utc_offset": 0
            }
            """

        try checkPayloadEquivalence(between: content0Data, and: expectedAttachmentEncodedContent, comparisons: ["automated", "hidden", "body"], shouldOpenContainer: false)

        try checkRequestHeading(for: self.attachmentTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "messages")
    }

    @Test func testEncodingWithAttachments() throws {
        let boundary = self.attachmentTestPayload.contentType?.components(separatedBy: ";")[1].components(separatedBy: "=")[1]

        let parts = try ApptentiveAPITests.parseMultipartBody(self.attachmentTestPayload.bodyData!, boundary: boundary!)

        #expect(parts.count == 3)

        #expect(parts[0].headers["Content-Type"] == "application/json;charset=UTF-8")
        #expect(parts[1].headers["Content-Type"] == "image/png")
        #expect(parts[2].headers["Content-Type"] == "image/jpeg")

        let content0Data = parts[0].content

        let expectedAttachmentEncodedContent = """
            {
                "automated": false,
                "body": "Test Attachments",
                "hidden": true,
                "nonce": "abc123",
                "client_created_at": 1600904569,
                "client_created_at_utc_offset": 0
            }
            """

        try checkPayloadEquivalence(between: content0Data, and: expectedAttachmentEncodedContent, comparisons: ["automated", "hidden", "body"], shouldOpenContainer: false)

        try checkRequestHeading(for: self.attachmentTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "messages")

        #expect(parts[1].content == data1)
        #expect(parts[2].content == data2)
    }

    @Test func testEncryptedEncoding() throws {
        // API requires single-part encrypted messages to be sent as multipart
        #expect(self.encryptedTestPayload.contentType!.hasPrefix("multipart"))

        let boundary = self.encryptedTestPayload.contentType?.components(separatedBy: ";")[1].components(separatedBy: "=")[1]

        let parts = try ApptentiveAPITests.parseMultipartBody(self.encryptedTestPayload.bodyData!, boundary: boundary!)

        // TODO: pick apart request and check body data?
        #expect(parts.count == 1)

        #expect(parts[0].headers["Content-Type"] == "application/octet-stream")

        let decryptedBody = try Data(parts[0].content).decrypted(with: self.encryptionKey)

        let bodyPart = try ApptentiveAPITests.parseMultipartPart(decryptedBody)

        let expectedEncodedContent = """
            {
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
            """

        try checkPayloadEquivalence(between: bodyPart.content, and: expectedEncodedContent, comparisons: ["message"], shouldOpenContainer: false)

        try checkEncryptedRequestHeading(for: self.encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "messages")
    }

    @Test func testEncryptedEncodingWithAttachments() throws {
        let boundary = self.encryptedAttachmentTestPayload.contentType?.components(separatedBy: ";")[1].components(separatedBy: "=")[1]

        let parts = try ApptentiveAPITests.parseMultipartBody(self.encryptedAttachmentTestPayload.bodyData!, boundary: boundary!)

        #expect(parts.count == 3)

        #expect(parts[0].headers["Content-Type"] == "application/octet-stream")

        let decryptedBody = try Data(parts[0].content).decrypted(with: self.encryptionKey)

        let bodyPart = try ApptentiveAPITests.parseMultipartPart(decryptedBody)

        let expectedAttachmentEncodedContent = """
            {
                "automated": false,
                "body": "Test Attachments",
                "hidden": true,
                "nonce": "abc123",
                "client_created_at": 1600904569,
                "client_created_at_utc_offset": 0
            }
            """

        try checkPayloadEquivalence(between: bodyPart.content, and: expectedAttachmentEncodedContent, comparisons: ["message"], shouldOpenContainer: false)

        try checkEncryptedRequestHeading(for: self.encryptedAttachmentTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "messages")
    }
}

class MockAttachmentURLProviding: AttachmentURLProviding {
    func url(for attachment: MessageList.Message.Attachment) -> URL? {
        return Bundle(for: type(of: self)).url(forResource: "dog", withExtension: "jpg")
    }
}
