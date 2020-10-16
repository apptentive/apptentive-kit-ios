//
//  Payload.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An HTTP request body object that wraps updates that are sent to the Apptentive API.
struct Payload: Codable {

    /// The payload contents that should be wrapped.
    let contents: PayloadContents

    /// A unique string that identifies this payload for deduplication on the server.
    let nonce: String

    /// The date/time at which the payload was created.
    let creationDate: Date

    /// The offset (in seconds) from UTC for the creation date.
    let creationUTCOffset: Int

    /// Creates a new payload object that wraps a survey response.
    /// - Parameter surveyResponse: The survey response to wrap.
    init(wrapping surveyResponse: SurveyResponse) {
        self.init(contents: .surveyResponse(SurveyResponseContents(response: surveyResponse)))
    }

    /// Initializes a new payload.
    /// - Parameter contents: The contents of the payload.
    private init(contents: PayloadContents) {
        self.nonce = UUID().uuidString
        self.creationDate = Date()
        self.creationUTCOffset = TimeZone.current.secondsFromGMT()

        self.contents = contents
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PayloadTypeCodingKeys.self)

        guard let containerKey = container.allKeys.first else {
            throw ApptentiveError.internalInconsistency
        }

        switch containerKey {
        case .response:
            self.contents = .surveyResponse(try container.decode(SurveyResponseContents.self, forKey: containerKey))
        }

        let nestedContainer = try container.nestedContainer(keyedBy: AllPossiblePayloadCodingKeys.self, forKey: containerKey)

        self.nonce = try nestedContainer.decode(String.self, forKey: .nonce)
        self.creationDate = try nestedContainer.decode(Date.self, forKey: .creationDate)
        self.creationUTCOffset = try nestedContainer.decode(Int.self, forKey: .creationUTCOffset)
    }

    func encode(to encoder: Encoder) throws {
        var encodingContainer = encoder.container(keyedBy: PayloadTypeCodingKeys.self)
        var nestedContainer = encodingContainer.nestedContainer(keyedBy: AllPossiblePayloadCodingKeys.self, forKey: self.contents.containerKey)

        try nestedContainer.encode(self.nonce, forKey: .nonce)
        try nestedContainer.encode(self.creationDate, forKey: .creationDate)
        try nestedContainer.encode(self.creationUTCOffset, forKey: .creationUTCOffset)

        try self.contents.encodeContents(to: &nestedContainer)
    }
}

enum PayloadTypeCodingKeys: String, CodingKey {
    case response
}

/// The union of coding keys from all payload types.
enum AllPossiblePayloadCodingKeys: String, CodingKey {
    case nonce
    case creationDate = "client_created_at"
    case creationUTCOffset = "client_created_at_utc_offset"
    case answers
}

/// The contents of the payload.
///
/// Each payload type has an associated value corresponding to its content.
enum PayloadContents: Equatable {
    case surveyResponse(SurveyResponseContents)

    var containerKey: PayloadTypeCodingKeys {
        switch self {
        case .surveyResponse:
            return .response
        }
    }

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
        switch self {
        case .surveyResponse(let surveyResponseContents):
            try surveyResponseContents.encodeContents(to: &container)
        }
    }
}

/// An empty object corresponding to the expected response when sending a payload.
struct PayloadResponse: Codable {}
