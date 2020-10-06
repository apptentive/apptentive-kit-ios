//
//  ConversationRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ConversationRequest: Codable, Equatable {
    init(conversation: Conversation) {
        self.appRelease = AppReleaseRequest(appRelease: conversation.appRelease)
        self.device = DeviceRequest(device: conversation.device)
        self.person = PersonRequest(person: conversation.person)
    }

    let appRelease: AppReleaseRequest
    let person: PersonRequest
    let device: DeviceRequest

    enum CodingKeys: String, CodingKey {
        case appRelease = "app_release"
        case person
        case device
    }
}

struct ConversationResponse: Codable, Equatable {
    let token: String
    let id: String
    let deviceID: String?
    let personID: String

    private enum CodingKeys: String, CodingKey {
        case token = "token"
        case id
        case deviceID = "device_id"
        case personID = "person_id"
    }
}
