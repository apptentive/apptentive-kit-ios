//
//  ConversationRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// The HTTP request body object sent when creating a conversation on the server.
struct ConversationRequest: Codable, Equatable, HTTPBodyPart {
    var contentType: String = HTTPContentType.json

    var filename: String? = nil

    var parameterName: String? = nil

    func content(using encoder: JSONEncoder) throws -> Data {
        return try encoder.encode(self)
    }

    init(conversation: Conversation, token: String?) {
        self.appRelease = AppReleaseContent(with: conversation.appRelease)
        self.device = DeviceContent(with: conversation.device)
        self.person = PersonContent(with: conversation.person)
        self.token = token
    }

    let appRelease: AppReleaseContent
    let person: PersonContent
    let device: DeviceContent
    let token: String?

    enum CodingKeys: String, CodingKey {
        case appRelease = "app_release"
        case person
        case device
        case token
    }
}

/// The HTTP response body object received when a conversation is created on the server.
struct ConversationResponse: Codable, Equatable {
    let token: String
    let id: String
    let deviceID: String?
    let personID: String
    let encryptionKey: Data?

    private enum CodingKeys: String, CodingKey {
        case token
        case id
        case deviceID = "device_id"
        case personID = "person_id"
        case encryptionKey = "encryption_key"
    }
}
