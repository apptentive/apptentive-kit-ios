//
//  ConversationRoster.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/8/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ConversationRoster: Codable, Equatable {
    var active: Record?

    var loggedOut: [Record]

    struct Record: Codable, Equatable {
        var state: State

        var path: String

        enum State: Codable, Equatable {
            case placeholder
            case anonymousPending
            case legacyPending(legacyToken: String)
            case anonymous(credentials: ConversationCredentials)
            case loggedIn(credentials: ConversationCredentials, subject: String, encryptionKey: Data)
            case loggedOut(id: String, subject: String)
        }
    }
}

extension ConversationRoster {
    func loggedOutRecord(with subject: String) -> Record? {
        return self.loggedOut.first(where: { record in
            record.subject == subject
        })
    }

    mutating func registerAnonymousRecord(with id: String, token: String) throws {
        guard case .anonymousPending = self.active?.state else {
            throw ApptentiveError.internalInconsistency
        }

        self.active?.state = .anonymous(credentials: .init(id: id, token: token))
    }

    mutating func logInLoggedOutRecord(with subject: String, token: String, encryptionKey: Data) throws {
        guard var record = self.loggedOut.first(where: { $0.subject == subject }), let id = record.id else {
            throw ApptentiveError.internalInconsistency
        }

        record.state = .loggedIn(credentials: .init(id: id, token: token), subject: subject, encryptionKey: encryptionKey)

        self.loggedOut.removeAll(where: { $0.subject == subject })

        self.active = record
    }

    mutating func createLoggedInRecord(with subject: String, id: String, token: String, encryptionKey: Data?) throws {
        guard let encryptionKey = encryptionKey else {
            throw ApptentiveError.internalInconsistency
        }

        self.active = Record(state: .loggedIn(credentials: .init(id: id, token: token), subject: subject, encryptionKey: encryptionKey), path: UUID().uuidString)
    }

    mutating func logInAnonymousRecord(with subject: String, token: String, encryptionKey: Data?) throws {
        guard case .anonymous(credentials: var credentials) = self.active?.state, let encryptionKey = encryptionKey else {
            throw ApptentiveError.internalInconsistency
        }

        credentials.token = token
        self.active?.state = .loggedIn(credentials: credentials, subject: subject, encryptionKey: encryptionKey)
    }

    mutating func logOutActiveConversation() throws {
        guard case .loggedIn(credentials: let credentials, subject: let subject, encryptionKey: _) = self.active?.state, var record = self.active else {
            throw ApptentiveError.internalInconsistency
        }

        record.state = .loggedOut(id: credentials.id, subject: subject)
        self.active = nil
        self.loggedOut.append(record)
    }

    mutating func updateLoggedInRecord(with token: String, matching subject: String) throws {
        guard case .loggedIn(credentials: let credentials, subject: let loggedInSubject, encryptionKey: let encryptionKey) = self.active?.state else {
            throw ApptentiveError.notLoggedIn
        }

        guard loggedInSubject == subject else {
            throw ApptentiveError.mismatchedSubClaim
        }

        self.active?.state = .loggedIn(credentials: .init(id: credentials.id, token: token), subject: subject, encryptionKey: encryptionKey)
    }
}

extension ConversationRoster.Record {
    var subject: String? {
        return self.subjectAndID?.subject
    }

    var id: String? {
        return self.subjectAndID?.id
    }

    private var subjectAndID: (subject: String?, id: String)? {
        switch self.state {
        case .loggedIn(credentials: let conversationCredentials, let subject, encryptionKey: _):
            return (subject, conversationCredentials.id)

        case .loggedOut(let id, let subject):
            return (subject, id)

        case .anonymous(credentials: let conversationCredentials):
            return (nil, conversationCredentials.id)

        default:
            return nil
        }
    }

    var encryptionKey: Data? {
        if case .loggedIn(credentials: _, subject: _, encryptionKey: let encryptionKey) = self.state {
            return encryptionKey
        } else {
            return nil
        }
    }

    static func randomPath() -> String {
        return UUID().uuidString
    }
}
