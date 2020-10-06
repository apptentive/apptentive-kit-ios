//
//  Payload.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Payload: Codable {
    let contents: PayloadContents
    let nonce: String
    let creationDate: Date
    let creationUTCOffset: Int

    init(wrapping surveyResponse: SurveyResponse) {
        self.init(contents: .surveyResponse(SurveyResponseContents(response: surveyResponse)))
    }

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

enum AllPossiblePayloadCodingKeys: String, CodingKey {
    case nonce
    case creationDate = "client_created_at"
    case creationUTCOffset = "client_created_at_utc_offset"
    case answers
}

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

struct PayloadResponse: Codable {}
