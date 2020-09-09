//
//  Conversation.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias ConversationEnvironment = DeviceEnvironment & AppEnvironment

struct Conversation {
    var appCredentials: Apptentive.AppCredentials?
    var conversationCredentials: ConversationCredentials?

    struct ConversationCredentials: Equatable, Codable {
        let token: String
        let id: String
    }

    var appRelease: AppRelease
    var person: Person
    var device: Device

    init(environment: ConversationEnvironment) {
        self.appRelease = AppRelease(environment: environment)
        self.person = Person()
        self.device = Device(environment: environment)
    }
}
