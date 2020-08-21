//
//  ApptentiveV9API.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/11/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ApptentiveV9API: HTTPEndpoint {
    let method: String
    let bodyEncodable: HTTPBodyEncodable?

    private let path: String
    private let conversation: Conversation

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: - Endpoints

    static func createConversation(_ conversation: Conversation) -> Self {
        let bodyObject = ConversationRequest(conversation: conversation)

        return Self(conversation: conversation, path: "conversations", method: Method.post, bodyObject: HTTPBodyEncodable(value: bodyObject))
    }

    // MARK: - HTTPEndpoint

    func url(relativeTo baseURL: URL) throws -> URL {
        guard let url = URL(string: self.path, relativeTo: baseURL) else {
            throw ApptentiveV9APIError.invalidURLString(self.path)
        }

        return url
    }

    func headers() throws -> [String: String] {
        guard let appCredentials = self.conversation.appCredentials else {
            throw ApptentiveV9APIError.missingAppCredentials
        }

        return Self.buildHeaders(
            appCredentials: appCredentials,
            userAgent: Self.userAgent(sdkVersion: self.conversation.sdkVersion),
            contentType: ContentType.json,
            apiVersion: Self.apiVersion)
    }

    func body() throws -> Data? {
        return try self.bodyEncodable.flatMap {
            try Self.encoder.encode($0)
        }
    }

    static func transformResponseData<T>(_ data: Data) throws -> T where T: Decodable {
        return try Self.decoder.decode(T.self, from: data)
    }

    // MARK: - Internals

    init(conversation: Conversation, path: String, method: String, bodyObject: HTTPBodyEncodable? = nil) {
        self.conversation = conversation
        self.path = path
        self.method = method
        self.bodyEncodable = bodyObject
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
        apiVersion: String
    ) -> [String: String] {
        let headers = [
            Headers.userAgent: userAgent,
            Headers.contentType: contentType,
            Headers.apiVersion: apiVersion,
            Headers.apptentiveKey: appCredentials.key,
            Headers.apptentiveSignature: appCredentials.signature,
        ]

        return headers
    }

    struct Headers {
        static let apptentiveKey = "APPTENTIVE-KEY"
        static let apptentiveSignature = "APPTENTIVE-SIGNATURE"
        static let apiVersion = "X-API-Version"
        static let userAgent = "User-Agent"
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
    }

    struct Method {
        static let get = "GET"
        static let put = "PUT"
        static let post = "POST"
        static let delete = "DELETE"
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
}

enum ApptentiveV9APIError: Error {
    case missingAppCredentials
    case invalidURLString(String)

    var localizedDescription: String {
        switch self {
        case .missingAppCredentials:
            return "Missing app credentials (key and signature)"

        case .invalidURLString(let urlString):
            return "Invalid URL string: \(urlString)"
        }
    }
}
