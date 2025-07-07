//
//  BackendState.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct BackendState: Equatable, Sendable {
    var isInForeground: Bool
    var isProtectedDataAvailable: Bool
    var appCredentials: Apptentive.AppCredentials?
    var roster: ConversationRoster
    var fatalError: Bool

    var anonymousCredentials: AnonymousAPICredentials? {
        switch (self.appCredentials, self.roster.active?.state) {
        case (.some(let appCredentials), .anonymous(credentials: let conversationCredentials)):
            return .init(appCredentials: appCredentials, conversationCredentials: conversationCredentials)

        case (.some(let appCredentials), .loggedIn(credentials: let conversationCredentials, subject: _, encryptionKey: _)):
            return .init(appCredentials: appCredentials, conversationCredentials: conversationCredentials)

        default:
            return nil
        }
    }

    var encryptionKey: Data? {
        return self.roster.active?.encryptionKey
    }

    var summary: Summary {
        switch (self.isInForeground, self.isProtectedDataAvailable, self.appCredentials, self.roster.active?.state, self.fatalError) {
        case (false, _, _, _, false):
            return .backgrounded

        case (true, false, _, .placeholder, false),
            (true, true, .none, .placeholder, false):
            return .waiting

        case (true, true, .some(let appCredentials), .placeholder, false):
            return .loading(appCredentials: appCredentials)

        case (true, true, .some(let appCredentials), .anonymousPending, false):
            return .posting(pendingCredentials: PendingAPICredentials(appCredentials: appCredentials))

        case (true, true, .some, .anonymous(let credentials), false):
            return .anonymous(payloadCredentials: .header(id: credentials.id, token: credentials.token))

        case (true, true, .some, .loggedIn(credentials: let credentials, subject: _, encryptionKey: let encryptionKey), false):
            return .loggedIn(payloadCredentials: .embedded(id: credentials.id), encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: credentials.token))

        case (true, true, .some, .none, false):
            return .loggedOut

        case (true, false, _, _, false):
            return .locked

        default:
            apptentiveCriticalError("Invalid state: \(String(describing: self))")
            return .error
        }
    }

    enum Summary: Equatable {
        case waiting
        case loading(appCredentials: Apptentive.AppCredentials)
        case posting(pendingCredentials: PendingAPICredentials)
        case anonymous(payloadCredentials: PayloadStoredCredentials)
        case loggedIn(payloadCredentials: PayloadStoredCredentials, encryptionContext: Payload.Context.EncryptionContext)
        case loggedOut
        case locked
        case backgrounded
        case error
    }
}
