//
//  SurveyResponseContents.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Encapsulates the payload contents for a survey response.
struct SurveyResponseContents: Equatable, Decodable, PayloadEncodable {
    let answers: SurveyAnswersRequestPart

    init(with response: SurveyResponse) {
        self.answers = SurveyAnswersRequestPart(answers: response.answers)
    }

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
        try container.encode(self.answers, forKey: .answers)
    }
}

/// The survey response payload part corresponding to the survey answers.
struct SurveyAnswersRequestPart: Codable, Equatable {
    let answers: [String: [Answer]]

    init(answers: [String: [Answer]]) {
        self.answers = answers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: QuestionIDCodingKeys.self)

        try self.answers.forEach { (key: String, questionResponses: [Answer]) in
            guard let questionIDCodingKey = QuestionIDCodingKeys.init(stringValue: key) else {
                return assertionFailure("Should always be able to create a QuestionIDCodingKeys instance with a string")
            }

            var questionContainer = container.nestedUnkeyedContainer(forKey: questionIDCodingKey)

            try questionResponses.forEach { (questionResponse) in
                var questionResponseContainer = questionContainer.nestedContainer(keyedBy: ChoiceCodingKeys.self)

                switch questionResponse {
                case .choice(let id):
                    try questionResponseContainer.encode(id, forKey: .id)
                case .freeform(let value):
                    try questionResponseContainer.encode(value, forKey: .value)
                case .other(let id, let value):
                    try questionResponseContainer.encode(id, forKey: .id)
                    try questionResponseContainer.encode(value, forKey: .value)
                case .range(let value):
                    try questionResponseContainer.encode(value, forKey: .value)
                }
            }
        }
    }

    init(from decoder: Decoder) throws {
        var keyedQuestionResponses = [String: [Answer]]()

        let container = try decoder.container(keyedBy: QuestionIDCodingKeys.self)

        try container.allKeys.forEach { (questionIDCodingKey) in
            var questionResponses = [Answer]()

            var questionContainer = try container.nestedUnkeyedContainer(forKey: questionIDCodingKey)

            while !questionContainer.isAtEnd {
                let responseContainer = try questionContainer.nestedContainer(keyedBy: ChoiceCodingKeys.self)

                if let intValue = try? responseContainer.decode(Int.self, forKey: .value) {
                    questionResponses.append(.range(intValue))
                } else if let stringID = try? responseContainer.decode(String.self, forKey: .id) {
                    if let stringValue = try? responseContainer.decode(String.self, forKey: .value) {
                        questionResponses.append(.other(stringID, stringValue))
                    } else {
                        questionResponses.append(.choice(stringID))
                    }
                } else if let stringValue = try? responseContainer.decode(String.self, forKey: .value) {
                    questionResponses.append(.freeform(stringValue))
                }
            }

            keyedQuestionResponses[questionIDCodingKey.stringValue] = questionResponses
        }

        self.answers = keyedQuestionResponses
    }

    struct QuestionIDCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int? = nil

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            self.stringValue = String(intValue)
        }
    }

    enum ChoiceCodingKeys: String, CodingKey {
        case id
        case value
    }
}
