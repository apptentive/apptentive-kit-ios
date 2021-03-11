//
//  ConversationRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// The HTTP request body object sent when creating a conversation on the server.
struct ConversationRequest: Codable, Equatable {
    init(conversation: Conversation) {
        self.appRelease = AppReleaseContents(with: conversation.appRelease)
        self.device = DeviceContents(with: conversation.device)
        self.person = PersonContents(with: conversation.person)
    }

    let appRelease: AppReleaseContents
    let person: PersonContents
    let device: DeviceContents

    enum CodingKeys: String, CodingKey {
        case appRelease = "app_release"
        case person
        case device
    }
}

/// The HTTP response body object received when a conversation is created on the server.
struct ConversationResponse: Codable, Equatable {
    let token: String
    let id: String
    let deviceID: String?
    let personID: String

    private enum CodingKeys: String, CodingKey {
        case token
        case id
        case deviceID = "device_id"
        case personID = "person_id"
    }
}
