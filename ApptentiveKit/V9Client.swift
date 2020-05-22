//
//  ApptentiveV9Client.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol ApptentiveClient {
    func createConversation(completion: @escaping (Bool) -> Void)
}

class V9Client: ApptentiveClient {
    let requestor: HTTPRequesting
    let credentials: Apptentive.AppCredentials
    let baseURL: URL
    let userAgent: String

    typealias HTTPHeaders = [String: String]

    required init(url: URL, appCredentials: Apptentive.AppCredentials, requestor: HTTPRequesting, platform: PlatformProtocol) {
        self.baseURL = url
        self.credentials = appCredentials
        self.requestor = requestor
        self.userAgent = Self.buildUserAgent(platform: platform)
    }

    struct Headers {
        static let apptentiveKey = "APPTENTIVE-KEY"
        static let apptentiveSignature = "APPTENTIVE-SIGNATURE"
        static let apiVersion = "X-API-Version"
        static let userAgent = "User-Agent"
        static let contentType = "Content-Type"
    }

    func createConversation(completion: @escaping (Bool) -> Void) {
        let url = baseURL.appendingPathComponent("conversations")
        let headers = Self.buildHeaders(credentials: self.credentials, userAgent: self.userAgent, contentType: "application/json")
        let request = Self.buildRequest(url: url, method: "POST", headers: headers)
        let transformer = Self.buildTransformer(type: ConversationResponse.self)

        requestor.sendRequest(request) { (result) in
            let transformedResult = Self.transformResult(result, transformer: transformer)

            switch transformedResult {
            case .success:
                completion(true)
            case .failure(let error):
                print("error is \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    static func buildTransformer<T: Decodable>(type: T.Type) -> (Data) -> Result<T, Error> {
        return { data in
            Result { try JSONDecoder().decode(type, from: data) }
        }
    }

    static func buildUserAgent(platform: PlatformProtocol) -> String {
        return "Apptentive/\(platform.sdkVersion.versionString) (Apple)"
    }

    static func buildHeaders(credentials: Apptentive.AppCredentials, userAgent: String, contentType: String) -> HTTPHeaders {
        return [
            Headers.apptentiveKey: credentials.key,
            Headers.apptentiveSignature: credentials.signature,
            Headers.apiVersion: "9",
            Headers.userAgent: userAgent,
            Headers.contentType: contentType,
        ]
    }

    static func buildRequest(url: URL, method: String, headers: HTTPHeaders) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers

        return request
    }

    static func transformResult<T>(_ result: HTTPResult, transformer: (Data) -> Result<T, Error>) -> Result<T, Error> {
        switch result {
        case .success(let (data, _)):
            return Result.success(data).flatMap(transformer)
        case .failure(let error):
            // TODO: handle retry for server and connection errors
            return .failure(error)
        }
    }
}

struct ConversationResponse: Codable, Equatable {
    let token: String
    let identifier: String
    let deviceIdentifier: String?
    let personIdentifier: String

    private enum CodingKeys: String, CodingKey {
        case token = "token"
        case identifier = "id"
        case deviceIdentifier = "device_id"
        case personIdentifier = "person_id"
    }
}
