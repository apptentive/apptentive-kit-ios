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
        switch (self.isInForeground, self.isProtectedDataAvailable, self.appCredentials, self.roster.active?.state, self.fatalError, self.roster.sdkEnabled ?? true) {
        case (false, _, _, _, false, true):
            return .backgrounded

        case (true, false, _, .placeholder, false, true),
            (true, true, .none, .placeholder, false, true):
            return .waiting

        case (true, true, .some(let appCredentials), .placeholder, false, true):
            return .loading(appCredentials: appCredentials)

        case (true, true, .some(let appCredentials), .anonymousPending, false, true):
            return .posting(pendingCredentials: PendingAPICredentials(appCredentials: appCredentials))

        case (true, true, .some, .anonymous(let credentials), false, true):
            return .anonymous(payloadCredentials: .secure(id: credentials.id), authenticationContext: .init(encryptionKey: nil, token: credentials.token))

        case (true, true, .some, .loggedIn(credentials: let credentials, subject: _, encryptionKey: let encryptionKey), false, true):
            return .loggedIn(payloadCredentials: .embedded(id: credentials.id), authenticationContext: .init(encryptionKey: encryptionKey, token: credentials.token))

        case (true, true, .some, .none, false, true):
            return .loggedOut

        case (_, _, _, _, _, false):
            return .disabled

        case (true, false, _, _, false, true):
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
        case anonymous(payloadCredentials: PayloadStoredCredentials, authenticationContext: Payload.Context.AuthenticationContext)
        case loggedIn(payloadCredentials: PayloadStoredCredentials, authenticationContext: Payload.Context.AuthenticationContext)
        case loggedOut
        case locked
        case backgrounded
        case disabled
        case error
    }
}
