//
//  ApptentiveAPI.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/11/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Configures a URL request corresponding to an endpoint on the Apptentive API.
struct ApptentiveAPI: HTTPEndpoint {

    /// The HTTP method for this endpoint.
    let method: HTTPMethod

    /// Whether this request requires conversation credentials (true for all but the initial conversation creation request).
    let requiresConversationCredentials: Bool

    /// The path of the request.
    ///
    /// When `requiresCredentials` is true, the path is automatically prepended with `conversations/<conversation ID>`.
    private let path: String

    /// The conversation object initiating the request (used to obtain app and conversation credentials).
    private let credentials: APICredentialsProviding

    /// The JSON encoder used for encoding the HTTP request body.
    private let encoder: JSONEncoder

    /// The JSON decoder used for decoding the HTTP response body.
    private let decoder: JSONDecoder

    private let bodyParts: [HTTPBodyPart]

    private let queryItems: [URLQueryItem]?

    let boundaryString: String

    private var contentType: String? {
        switch self.bodyParts.count {
        case 0:
            return .none

        case 1:
            return self.bodyParts[0].contentType

        default:
            return HTTPContentType.multipart(boundary: self.boundaryString)
        }
    }

    // MARK: - Endpoints

    /// Builds a request to create a conversation on the server.
    /// - Parameter conversation: The conversation to be created.
    /// - Returns: A struct describing the HTTP request to be performed.
    static func createConversation(_ conversation: Conversation) -> Self {
        return Self(credentials: conversation, path: "conversations", method: .post, bodyObject: ConversationRequest(conversation: conversation), requiresConversationCredentials: false)
    }

    /// Builds a request to retrieve an engagement manifest from the server.
    /// - Parameter credentials: The conversation for which to retrieve the manifest.
    /// - Returns: A struct describing the HTTP request to be performed.
    static func getInteractions(with credentials: APICredentialsProviding) -> Self {
        return Self(credentials: credentials, path: "interactions", method: .get)
    }

    /// Builds a request to retrieve a message list from the server.
    /// - Parameters:
    ///   - credentials: The conversation for which to retrieve the message list.
    ///   - lastMessageID: The message ID from the `after_id` field of the previous response, if any.
    /// - Returns: A struct describing the HTTP request to be performed.
    static func getMessages(with credentials: APICredentialsProviding, afterMessageWithID lastMessageID: String?) -> Self {
        let queryItems = lastMessageID.flatMap { [URLQueryItem(name: "starts_after", value: $0)] }

        return Self(credentials: credentials, path: "messages", queryItems: queryItems, method: .get)
    }

    /// Builds a request to retrieve a message list from the server.
    /// - Parameter credentials: The conversation for which to retrieve the message list.
    /// - Returns: A struct describing the HTTP request to be performed.
    static func getConfiguration(with credentials: APICredentialsProviding) -> Self {
        return Self(credentials: credentials, path: "configuration", method: .get)
    }

    // MARK: - HTTPEndpoint

    /// Returns the URL for the endpoint.
    /// - Parameter baseURL: The URL relative to which requests should be made.
    /// - Throws: An error if inssufficient credentials are provided.
    /// - Returns: A URL for the request.
    func url(relativeTo baseURL: URL) throws -> URL {
        var fullPath = self.path

        if self.requiresConversationCredentials {
            guard let conversationID = self.credentials.conversationCredentials?.id else {
                throw ApptentiveAPIError.missingConversationCredentials
            }

            // Credentialed requests need to be scoped to the conversation.
            fullPath = "conversations/\(conversationID)/\(path)"
        }

        var components = URLComponents()
        components.path = fullPath
        components.queryItems = self.queryItems

        guard let url = components.url(relativeTo: baseURL) else {
            throw ApptentiveAPIError.invalidURLString(self.path)
        }

        return url
    }

    /// Returns the HTTP headers for the endpoint.
    /// - Throws: An error if insufficient credentials are provided.
    /// - Returns: The HTTP headers to use for the request.
    func headers() throws -> [String: String] {
        guard let appCredentials = self.credentials.appCredentials else {
            throw ApptentiveAPIError.missingAppCredentials
        }

        let token = self.credentials.conversationCredentials?.token

        guard token != nil || !self.requiresConversationCredentials else {
            throw ApptentiveAPIError.missingConversationCredentials
        }

        return Self.buildHeaders(
            appCredentials: appCredentials,
            contentType: self.contentType,
            accept: HTTPContentType.json,
            acceptCharset: "UTF-8",
            acceptLanguage: self.credentials.acceptLanguage ?? "en",
            apiVersion: Self.apiVersion,
            token: token)
    }

    /// Returns the HTTP body data for the endpoint.
    /// - Throws: An error if the body fails to encode.
    /// - Returns: The HTTP body data for the request.
    func body() throws -> Data? {
        switch self.bodyParts.count {
        case 0:
            return nil

        case 1:
            return try Self.encode(self.bodyParts[0], with: self.encoder)

        default:
            return try Self.encodeMultipart(self.bodyParts, with: self.encoder, boundary: self.boundaryString)
        }
    }

    /// Decodes the HTTP response to the correct type.
    ///
    /// If the response object conforms to the `Expiring` protocol, its `expiry` property will be set according to the `Cache-Control` header.
    /// - Parameter response: The response object to decode.
    /// - Throws: And error if the response can't be decoded.
    /// - Returns: The decoded response object.
    func transformResponse<T>(_ response: HTTPResponse) throws -> T where T: Decodable {
        let responseObject: T = try {
            if response.data.count == 0 {
                // Empty data is not valid JSON, so we need to use a custom placeholder decoder.
                return try T(from: EmptyDecoder())
            } else {
                return try self.decoder.decode(T.self, from: response.data)
            }
        }()

        // If the response object conforms to `Expiring`, set its `expiry` property.
        if var expiring = responseObject as? Expiring {
            expiring.expiry = Self.parseExpiry(response.response)

            // swift-format-ignore
            return expiring as! T
        }

        return responseObject
    }

    /// Initializes a new request for the endpoint with an optional `Encodable` object to send as the body of the request.
    /// - Parameters:
    ///   - credentials: The provider of credentials to use when connecting to the API.
    ///   - path: The path of the request, scoped to the conversation if appropriate.
    ///   - queryItems: A list of key-value pairs to include in the query portion of the request URL.
    ///   - method: The HTTP method for the request.
    ///   - bodyObject: The object that should be encoded for the HTTP body of the request.
    ///   - requiresConversationCredentials: Whether the request should send conversation credentials and be scoped to the conversation.
    init(credentials: APICredentialsProviding, path: String, queryItems: [URLQueryItem]? = nil, method: HTTPMethod, bodyObject: HTTPBodyPart? = nil, requiresConversationCredentials: Bool = true) {
        var bodyParts = [HTTPBodyPart]()

        if let bodyObject = bodyObject {
            bodyParts.append(bodyObject)
        }

        self.init(credentials: credentials, path: path, queryItems: queryItems, method: method, bodyParts: bodyParts, requiresConversationCredentials: requiresConversationCredentials)
    }

    /// Initializes a new request for the endpoint.
    /// - Parameters:
    ///   - credentials: The provider of credentials to use when connecting to the API.
    ///   - path: The path of the request, scoped to the conversation if appropriate.
    ///   - queryItems: A list of key-value pairs to include in the query portion of the request URL.
    ///   - method: The HTTP method for the request.
    ///   - bodyParts: An array of content to use as part of the request body (an empty array indicates no request body).
    ///   - requiresConversationCredentials: Whether the request should send conversation credentials and be scoped to the conversation.
    init(credentials: APICredentialsProviding, path: String, queryItems: [URLQueryItem]? = nil, method: HTTPMethod, bodyParts: [HTTPBodyPart], requiresConversationCredentials: Bool = true) {
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .secondsSince1970

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .secondsSince1970

        self.credentials = credentials
        self.path = path
        self.queryItems = queryItems
        self.method = method
        self.bodyParts = bodyParts

        self.requiresConversationCredentials = requiresConversationCredentials
        self.boundaryString = Self.createRandomString()
    }

    static func encode(_ bodyPart: HTTPBodyPart, with encoder: JSONEncoder) throws -> Data {
        return try bodyPart.content(using: encoder)
    }

    static func encodeMultipart(_ bodyParts: [HTTPBodyPart], with encoder: JSONEncoder, boundary boundaryString: String) throws -> Data {
        guard let boundary = boundaryString.data(using: .utf8),
            let dashes = "--".data(using: .utf8),
            let crlf = "\r\n".data(using: .utf8)
        else {
            throw ApptentiveError.internalInconsistency
        }

        var result = Data()
        try bodyParts.forEach { part in
            guard let contentDispositionHeader = "Content-Disposition: \(part.contentDisposition)".data(using: .utf8),
                let contentTypeHeader = "Content-Type: \(part.contentType)".data(using: .utf8)
            else {
                throw ApptentiveError.internalInconsistency
            }

            result.append(dashes + boundary + crlf)
            result.append(contentDispositionHeader + crlf)
            result.append(contentTypeHeader + crlf)
            result.append(crlf)
            result.append(try part.content(using: encoder))
            result.append(crlf)
        }

        result.append(dashes + boundary + dashes)

        return result
    }

    static func createRandomString() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }

    /// The API version to send for the request.
    static var apiVersion: String {
        "12"
    }

    /// The string to be sent for the request's `User-Agent` header.
    /// - Parameter sdkVersion: The version of the SDK making the request.
    /// - Returns: The user agent string.
    static func userAgent(sdkVersion: Version) -> String {
        return "Apptentive/\(sdkVersion.versionString) (Apple)"
    }

    /// Builds the HTTP header dictionary for the specified parameters.
    /// - Parameters:
    ///   - appCredentials: The app key and app signature for the request.
    ///   - contentType: The content type for the request.
    ///   - accept: The content type that the request expects to receive in response.
    ///   - acceptCharset: The character set that the request expects the response to be encoded with.
    ///   - acceptLanguage: The (natural) language that the request expects the response to be in.
    ///   - apiVersion: The API version for the request.
    ///   - token: The JWT for the request, if any.
    /// - Returns: A dictionary whose keys are header names and whose values are the corresponding header values.
    static func buildHeaders(
        appCredentials: Apptentive.AppCredentials,
        contentType: String?,
        accept: String,
        acceptCharset: String,
        acceptLanguage: String,
        apiVersion: String,
        token: String?
    ) -> [String: String] {
        var headers = [
            Header.apiVersion: apiVersion,
            Header.apptentiveKey: appCredentials.key,
            Header.apptentiveSignature: appCredentials.signature,
            Header.accept: accept,
            Header.acceptCharset: acceptCharset,
            Header.acceptLanguage: acceptLanguage,
        ]

        if let contentType = contentType {
            headers[Header.contentType] = contentType
        }

        if let token = token {
            headers[Header.authorization] = "Bearer \(token)"
        }

        return headers
    }

    /// Parses the date after which the resource should be considered stale.
    /// - Parameter response: The HTTP response whose headers shoud be parsed.
    /// - Returns: A date after which the resource should be considered stale, or nil if the header was missing or could not be parsed.
    static func parseExpiry(_ response: HTTPURLResponse) -> Date? {
        if let cacheControlHeader = response.allHeaderFields["Cache-Control"] as? String {
            let scanner = Scanner(string: cacheControlHeader.lowercased())
            var maxAge: Double = .nan
            if scanner.scanString("max-age", into: nil) && scanner.scanString("=", into: nil) && scanner.scanDouble(&maxAge) {
                maxAge = max(maxAge, 600)  // API has a bug where it sends a max-age of zero sometimes.
                return Date(timeIntervalSinceNow: maxAge)
            }
        }
        return nil
    }

    /// The header names used for Apptentive API requests.
    struct Header {
        static let apptentiveKey = "APPTENTIVE-KEY"
        static let apptentiveSignature = "APPTENTIVE-SIGNATURE"
        static let apiVersion = "X-API-Version"
        static let contentType = "Content-Type"
        static let authorization = "Authorization"
        static let acceptCharset = "Accept-Charset"
        static let acceptLanguage = "Accept-Language"
        static let accept = "Accept"
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
            throw ApptentiveAPIError.missingResponseData
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw ApptentiveAPIError.missingResponseData
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw ApptentiveAPIError.missingResponseData
        }
    }
}

enum ApptentiveAPIError: Error {
    case missingAppCredentials
    case missingConversationCredentials
    case missingResponseData
    case invalidURLString(String)
}

extension ApptentiveAPIError: LocalizedError {
    var errorDescription: String? {
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
