//
//  ApptentiveV9API.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/11/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ApptentiveV9API: HTTPEndpoint {
    let method: HTTPMethod
    let bodyEncodable: HTTPBodyEncodable?
    let requiresCredentials: Bool

    private let path: String
    private let conversation: Conversation

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Endpoints

    static func createConversation(_ conversation: Conversation) -> Self {
        let bodyObject = ConversationRequest(conversation: conversation)

        return Self(conversation: conversation, path: "conversations", method: .post, bodyObject: HTTPBodyEncodable(value: bodyObject), requiresCredentials: false)
    }

    static func createSurveyResponse(_ surveyResponse: SurveyResponse, for conversation: Conversation) -> Self {
        let bodyObject = Payload(wrapping: surveyResponse)

        return Self(conversation: conversation, path: "surveys/\(surveyResponse.surveyID)/responses", method: .post, bodyObject: HTTPBodyEncodable(value: bodyObject))
    }

    static func getInteractions(for conversation: Conversation) -> Self {
        return Self(conversation: conversation, path: "interactions", method: .get)
    }

    // MARK: - HTTPEndpoint

    func url(relativeTo baseURL: URL) throws -> URL {
        var fullPath = self.path

        if self.requiresCredentials {
            guard let conversationID = self.conversation.conversationCredentials?.id else {
                throw ApptentiveV9APIError.missingConversationCredentials
            }

            // Credentialed requests need to be scoped to the conversation
            fullPath = "conversations/\(conversationID)/\(path)"
        }

        guard let url = URL(string: fullPath, relativeTo: baseURL) else {
            throw ApptentiveV9APIError.invalidURLString(self.path)
        }

        return url
    }

    func headers() throws -> [String: String] {
        guard let appCredentials = self.conversation.appCredentials else {
            throw ApptentiveV9APIError.missingAppCredentials
        }

        let token = self.conversation.conversationCredentials?.token

        guard token != nil || !self.requiresCredentials else {
            throw ApptentiveV9APIError.missingConversationCredentials
        }

        return Self.buildHeaders(
            appCredentials: appCredentials,
            userAgent: Self.userAgent(sdkVersion: self.conversation.appRelease.sdkVersion),
            contentType: ContentType.json,
            apiVersion: Self.apiVersion,
            token: token)
    }

    func body() throws -> Data? {
        return try self.bodyEncodable.flatMap {
            try self.encoder.encode($0)
        }
    }

    func transformResponse<T>(_ response: HTTPResponse) throws -> T where T: Decodable {
        let responseObject: T = try {
            if response.data.count == 0 {
                return try T(from: EmptyDecoder())
            } else {
                return try self.decoder.decode(T.self, from: response.data)
            }
        }()

        if var expiring = responseObject as? Expiring {
            expiring.expiry = Self.parseExpiry(response.response)

            // swift-format-ignore
            return expiring as! T
        }

        return responseObject
    }

    // MARK: - Internals

    init(conversation: Conversation, path: String, method: HTTPMethod, bodyObject: HTTPBodyEncodable? = nil, requiresCredentials: Bool? = nil) {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .secondsSince1970

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .secondsSince1970

        self.conversation = conversation
        self.path = path
        self.method = method
        self.bodyEncodable = bodyObject

        self.requiresCredentials = requiresCredentials ?? true
    }

    static var apiVersion: String {
        "9"
    }

    static func userAgent(sdkVersion: String) -> String {
        return "Apptentive/\(sdkVersion) (Apple)"
    }

    static func buildHeaders(
        appCredentials: Apptentive.AppCredentials,
        userAgent: String,
        contentType: String,
        apiVersion: String,
        token: String?
    ) -> [String: String] {
        var headers = [
            Headers.userAgent: userAgent,
            Headers.contentType: contentType,
            Headers.apiVersion: apiVersion,
            Headers.apptentiveKey: appCredentials.key,
            Headers.apptentiveSignature: appCredentials.signature,
        ]

        if let token = token {
            headers[Headers.authorization] = "Bearer \(token)"
        }

        return headers
    }

    static func parseExpiry(_ response: HTTPURLResponse) -> Date? {
        if let cacheControlHeader = response.allHeaderFields["Cache-Control"] as? String {
            let scanner = Scanner(string: cacheControlHeader.lowercased())
            var maxAge: Double = .nan
            if scanner.scanString("max-age", into: nil) && scanner.scanString("=", into: nil) && scanner.scanDouble(&maxAge) {
                return Date(timeIntervalSinceNow: maxAge)
            }
        }
        return nil
    }

    struct Headers {
        static let apptentiveKey = "APPTENTIVE-KEY"
        static let apptentiveSignature = "APPTENTIVE-SIGNATURE"
        static let apiVersion = "X-API-Version"
        static let userAgent = "User-Agent"
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
    }

    struct ContentType {
        static let json = "application/json"
    }

    /// Type-erasing `Encodable` container.
    struct HTTPBodyEncodable: Encodable {
        let value: Encodable

        func encode(to encoder: Encoder) throws {
            try self.value.encode(to: encoder)
        }
    }

    /// A placeholder `Decoder` that doesn't choke on zero-length data.
    ///
    /// Decoding will succeed as long as the type using the decoder to decode doesn't attempt to decode any properties.
    struct EmptyDecoder: Decoder {
        var codingPath: [CodingKey] {
            []
        }

        var userInfo: [CodingUserInfoKey: Any] {
            [:]
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
            throw ApptentiveV9APIError.missingResponseData
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw ApptentiveV9APIError.missingResponseData
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw ApptentiveV9APIError.missingResponseData
        }
    }
}

enum ApptentiveV9APIError: Error {
    case missingAppCredentials
    case missingConversationCredentials
    case missingResponseData
    case invalidURLString(String)

    var localizedDescription: String {
        switch self {
        case .missingAppCredentials:
            return "Missing app credentials (key and signature)"

        case .missingConversationCredentials:
            return "Missing conversation credentials (id and token)"

        case .missingResponseData:
            return "A request that should return data didn't"

        case .invalidURLString(let urlString):
            return "Invalid URL string: \(urlString)"
        }
    }
}
