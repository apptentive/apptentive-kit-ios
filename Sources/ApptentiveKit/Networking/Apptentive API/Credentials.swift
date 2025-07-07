//
//  Credentials.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/6/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes an object that can supply credentials for accessing the Apptentive API.
protocol APICredentialsProviding: Sendable {

    /// The headers to include with an API request for this type of credential.
    var headers: [String: String] { get }

    /// A function that may modify the path of the request's URL.
    func transformPath(_ path: String) -> String
}

extension Apptentive.AppCredentials: APICredentialsProviding {

    /// Returns values for the Apptentive Key and Apptentive Signature headers.
    var headers: [String: String] {
        return [ApptentiveAPI.Header.apptentiveKey: self.key, ApptentiveAPI.Header.apptentiveSignature: self.signature]
    }

    /// Returns the path without modification.
    func transformPath(_ path: String) -> String {
        return path
    }
}

/// Encapsulates the credentials needed to make an API request for an anonymous conversation.
struct ConversationCredentials: Codable, Equatable {
    /// The ID for the conversation.
    let id: String

    /// The JWT to use for the authorization header.
    var token: String
}

struct PendingAPICredentials: APICredentialsProviding, Equatable {
    /// The credentials for the application, supplied by the customer via the `register(with:completion:)` method.
    let appCredentials: Apptentive.AppCredentials

    /// Returns values for the Apptentive Key and Apptentive Signature headers.
    var headers: [String: String] {
        return [
            ApptentiveAPI.Header.apptentiveKey: self.appCredentials.key,
            ApptentiveAPI.Header.apptentiveSignature: self.appCredentials.signature,
        ]
    }

    /// Returns the path without modification.
    func transformPath(_ path: String) -> String {
        return path
    }
}

struct AnonymousAPICredentials: APICredentialsProviding, Equatable {
    /// The credentials for the application, supplied by the customer via the `register(with:completion:)` method.
    let appCredentials: Apptentive.AppCredentials

    /// The conversation identifier and JWT that authenticates the conversation.
    let conversationCredentials: ConversationCredentials

    init(appCredentials: Apptentive.AppCredentials, conversationCredentials: ConversationCredentials) {
        self.appCredentials = appCredentials
        self.conversationCredentials = conversationCredentials
    }

    init(pendingCredentials: PendingAPICredentials, id: String, token: String) {
        self.appCredentials = pendingCredentials.appCredentials
        self.conversationCredentials = ConversationCredentials(id: id, token: token)
    }

    var pendingCredentials: PendingAPICredentials {
        .init(appCredentials: self.appCredentials)
    }

    /// Returns the headers for the app credentials along with an authorization header.
    var headers: [String: String] {
        var result = self.appCredentials.headers
        result[ApptentiveAPI.Header.authorization] = "Bearer \(self.conversationCredentials.token)"

        return result
    }

    /// Prepends `conversations` and the conversation ID as components to the supplied path.
    func transformPath(_ path: String) -> String {
        return "/conversations/\(self.conversationCredentials.id)/\(path)"
    }
}

struct AuthenticatedAPICredentials: APICredentialsProviding, Equatable {
    /// The credentials for the application, supplied by the customer via the `register(with:completion:)` method.
    let appCredentials: Apptentive.AppCredentials

    /// The conversation identifier and JWT that authenticates the conversation.
    let conversationCredentials: ConversationCredentials

    init(appCredentials: Apptentive.AppCredentials, conversationCredentials: ConversationCredentials) {
        self.appCredentials = appCredentials
        self.conversationCredentials = conversationCredentials
    }

    var anonymousCredentials: AnonymousAPICredentials {
        .init(appCredentials: self.appCredentials, conversationCredentials: self.conversationCredentials)
    }

    /// Returns the headers for the app credentials along with an authorization header.
    var headers: [String: String] {
        return self.appCredentials.headers
    }

    /// Prepends `conversations` and the conversation ID as components to the supplied path.
    func transformPath(_ path: String) -> String {
        return "/conversations/\(self.conversationCredentials.id)/\(path)"
    }
}

struct PayloadAPICredentials: APICredentialsProviding {
    let appCredentials: Apptentive.AppCredentials

    let payloadCredentials: PayloadStoredCredentials

    var headers: [String: String] {
        var result = self.appCredentials.headers

        switch self.payloadCredentials {
        case .header(id: _, let token):
            result[ApptentiveAPI.Header.authorization] = "Bearer \(token)"

        case .embedded:
            result[ApptentiveAPI.Header.apptentiveEncrypted] = "true"

        default:
            break
        }

        return result
    }

    func transformPath(_ path: String) -> String {
        if let id = self.payloadCredentials.id {
            return "/conversations/\(id)/\(path)"
        } else {
            apptentiveCriticalError("Expected conversation ID when transforming payload path.")
            return path
        }
    }
}

/// Represents the conversation credentials stored with a payload, which don't include the app credentials.
enum PayloadStoredCredentials: Codable, Equatable {
    case placeholder
    case header(id: String, token: String)
    case embedded(id: String)
    case invalidEmbedded

    /// Whether the credentials are complete enough to send an API request.
    var areValid: Bool {
        switch self {
        case .placeholder, .invalidEmbedded:
            return false

        default:
            return true
        }
    }

    var id: String? {
        switch self {
        case .header(let id, _):
            return id

        case .embedded(let id):
            return id

        default:
            return nil
        }
    }
}
