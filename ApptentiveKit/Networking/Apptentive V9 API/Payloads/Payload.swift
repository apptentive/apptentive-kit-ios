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

    /// The HTTP method to use for the API request.
    let method: HTTPMethod

    /// The path to use to build the URL for the API request.
    let path: String

    /// Creates a new payload object that wraps a survey response.
    /// - Parameter surveyResponse: The survey response to wrap.
    init(wrapping surveyResponse: SurveyResponse) {
        self.init(contents: .surveyResponse(SurveyResponseContents(response: surveyResponse)), path: "surveys/\(surveyResponse.surveyID)/responses", method: .post)
    }

    /// Creates a new payload object that wraps an event.
    /// - Parameter event: The event to wrap.
    init(wrapping event: Event) {
        self.init(contents: .event(EventContents(event: event)), path: "events", method: .post)
    }

    /// Initializes a new payload.
    /// - Parameters:
    ///   - contents: The contents of the payload.
    ///   - path: The path for the API request.
    ///   - method: The HTTP method for the API request.
    private init(contents: PayloadContents, path: String, method: HTTPMethod) {
        self.nonce = UUID().uuidString
        self.creationDate = Date()
        self.creationUTCOffset = TimeZone.current.secondsFromGMT()

        self.contents = contents
        self.path = path
        self.method = method
    }

    // This should only be used for testing.
    // Items decoded with this decoder will differ from the encoded version.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: PayloadTypeCodingKeys.self)

        guard let containerKey = container.allKeys.first else {
            throw ApptentiveError.internalInconsistency
        }

        switch containerKey {
        case .response:
            self.contents = .surveyResponse(try container.decode(SurveyResponseContents.self, forKey: containerKey))
            self.path = "surveys/<survey_id>/responses"
            self.method = .post
        case .event:
            self.contents = .event(try container.decode(EventContents.self, forKey: containerKey))
            self.path = "events"
            self.method = .post
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
    case event
}

/// The union of coding keys from all payload types.
enum AllPossiblePayloadCodingKeys: String, CodingKey {
    // Generic keys
    case nonce
    case creationDate = "client_created_at"
    case creationUTCOffset = "client_created_at_utc_offset"
    case sessionID = "session_id"

    // Survey response keys
    case answers

    // Event keys
    case label
    case interactionID = "interaction_id"
    case userInfo = "data"
    case customData = "custom_data"
    case time
    case location
    case commerce
}

/// The contents of the payload.
///
/// Each payload type has an associated value corresponding to its content.
enum PayloadContents: Equatable {
    case surveyResponse(SurveyResponseContents)
    case event(EventContents)

    var containerKey: PayloadTypeCodingKeys {
        switch self {
        case .surveyResponse:
            return .response
        case .event:
            return .event
        }
    }

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
        switch self {
        case .surveyResponse(let surveyResponseContents):
            try surveyResponseContents.encodeContents(to: &container)
        case .event(let eventContents):
            try eventContents.encodeContents(to: &container)
        }
    }
}

/// Describes an object that can encode its contents
/// (which must be added to the `AllPossiblePayloadCodingKeys` enumeration)
/// to an existing keyed encoding container.
protocol PayloadEncodable {

    /// Encodes the object's contents to the specified keyed encoding container.
    /// - Parameter container: The keyed encoding container that will be used to encode the object's contents.
    /// - Throws: An error if the encoding fails.
    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws
}

/// An empty object corresponding to the expected response when sending a payload.
struct PayloadResponse: Codable {}
