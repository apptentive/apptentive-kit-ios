//
//  PayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 3/23/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class PayloadTests: XCTestCase {

    func testParseParameters() throws {
        XCTAssertEqual(try Payload.parseParameters(from: "multipart/mixed;boundary=abc123"), ["boundary": "abc123"])
        XCTAssertEqual(try Payload.parseParameters(from: "multipart/mixed;boundary=\"abc123\""), ["boundary": "abc123"])
        XCTAssertEqual(try Payload.parseParameters(from: "multipart/mixed; boundary=abc123"), ["boundary": "abc123"])
        XCTAssertEqual(try Payload.parseParameters(from: "multipart/mixed; boundary=\"abc123\""), ["boundary": "abc123"])
    }

    func testUpdateCredentialsInPlaintextSinglePart() throws {
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let payloadContext = Payload.Context(tag: ".", credentials: .embedded(id: "abc"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, body: "testing"), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.header(id: "abc", token: "456"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: nil)

        XCTAssertEqual(payload.credentials, .header(id: "abc", token: "456"))
    }

    func testUpdateCredentialsInEncryptedSinglePart() throws {
        let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, body: "testing"), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.embedded(id: "abc"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "456"))

        let parts = try Payload.parseBodyData(of: payload, using: jsonDecoder, encryptionKey: encryptionKey)

        guard let jsonObject = parts[0] as? Payload.JSONObject else {
            XCTFail("Expected first part to be JSON object")
            return
        }

        XCTAssertEqual(jsonObject.embeddedToken, "456")
    }

    func testUpdateCredentialsInPlaintextMultipart() throws {
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, attachments: [attachment1, attachment2]), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.header(id: "abc", token: "456"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: nil)

        XCTAssertEqual(payload.credentials, .header(id: "abc", token: "456"))
    }

    func testUpdateCredentialsInEncryptedMultipart() throws {
        let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, attachments: [attachment1, attachment2]), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.embedded(id: "abc"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "456"))

        let parts = try Payload.parseBodyData(of: payload, using: jsonDecoder, encryptionKey: encryptionKey)

        guard let jsonObject = parts[0] as? Payload.JSONObject else {
            XCTFail("Expected first part to be JSON object")
            return
        }

        XCTAssertEqual(jsonObject.embeddedToken, "456")
    }

    func testConvertToEncryptedSinglePart() throws {
        let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, body: "testing"), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.header(id: "abc", token: "456"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "456"))

        let parts = try Payload.parseBodyData(of: payload, using: jsonDecoder, encryptionKey: encryptionKey)

        guard let jsonObject = parts[0] as? Payload.JSONObject else {
            XCTFail("Expected first part to be JSON object")
            return
        }

        XCTAssertEqual(jsonObject.embeddedToken, "456")
    }

    func testConvertToEncryptedMultipart() throws {
        let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let messageNonce = UUID().uuidString

        let jsonEncoder = JSONEncoder.apptentive
        let jsonDecoder = JSONDecoder.apptentive

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: jsonEncoder, encryptionContext: nil)

        var payload = try Payload(wrapping: MessageList.Message(nonce: messageNonce, attachments: [attachment1, attachment2]), with: payloadContext, attachmentURLProvider: MockAttachmentURLProviding())

        try payload.updateCredentials(.embedded(id: "abc"), using: jsonEncoder, decoder: jsonDecoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "456"))

        let parts = try Payload.parseBodyData(of: payload, using: jsonDecoder, encryptionKey: encryptionKey)

        guard let jsonObject = parts[0] as? Payload.JSONObject else {
            XCTFail("Expected first part to be JSON object")
            return
        }

        XCTAssertEqual(jsonObject.embeddedToken, "456")
    }
}
