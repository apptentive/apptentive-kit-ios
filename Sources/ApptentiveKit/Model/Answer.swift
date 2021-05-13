//
//  Answer.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object describing an answer to a question.
///
/// Questions that accept multiple answers will have more than one answer in the array for a particular question.
enum Answer: Equatable, Codable {
    case choice(String)
    case freeform(String)
    case range(Int)
    case other(String, String)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decodeIfPresent(String.self, forKey: .id)
        let stringValue = try container.decodeIfPresent(String.self, forKey: .stringValue)
        let intValue = try container.decodeIfPresent(Int.self, forKey: .intValue)

        switch (id, stringValue, intValue) {
        case (.some(let id), .none, .none):
            self = .choice(id)

        case (.some(let id), .some(let value), .none):
            self = .other(id, value)

        case (.none, .some(let value), .none):
            self = .freeform(value)

        case (.none, .none, .some(let value)):
            self = .range(value)

        default:
            throw ApptentiveError.internalInconsistency
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .choice(let id):
            try container.encode(id, forKey: .id)

        case .freeform(let value):
            try container.encode(value, forKey: .stringValue)

        case .range(let value):
            try container.encode(value, forKey: .intValue)

        case .other(let id, let value):
            try container.encode(id, forKey: .id)
            try container.encode(value, forKey: .stringValue)
        }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case stringValue
        case intValue
    }
}
