//
//  SessionRequest.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/6/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

/// The HTTP request body object sent when creating a conversation on the server.
struct SessionRequest: Codable, Equatable, HTTPBodyPart {
    var contentType: String = HTTPContentType.json

    var filename: String? = nil

    var parameterName: String? = nil

    func content(using encoder: JSONEncoder) throws -> Data {
        return try encoder.encode(self)
    }

    init(token: String) {
        self.token = token
    }

    let token: String

    enum CodingKeys: String, CodingKey {
        case token
    }
}

/// The HTTP response body object received when a conversation is created on the server.
struct SessionResponse: Codable, Equatable {
    let deviceID: String
    let personID: String
    let encryptionKey: Data

    private enum CodingKeys: String, CodingKey {
        case deviceID = "device_id"
        case personID = "person_id"
        case encryptionKey = "encryption_key"
    }
}
