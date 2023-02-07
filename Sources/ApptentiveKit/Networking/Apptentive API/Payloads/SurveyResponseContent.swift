//
//  SurveyResponseContent.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/18/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Encapsulates the payload contents for a survey response.
struct SurveyResponseContent: Equatable, Decodable, PayloadEncodable {
    let answers: SurveyV12AnswersRequestPart

    init(with response: SurveyResponse) {
        self.answers = SurveyV12AnswersRequestPart(questionResponses: response.questionResponses)
    }

    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
        try container.encode(self.answers, forKey: .answers)
    }
}

/// The survey response payload part corresponding to the survey answers.
struct SurveyV12AnswersRequestPart: Codable, Equatable {
    let questionResponses: [String: QuestionResponse]

    init(questionResponses: [String: QuestionResponse]) {
        self.questionResponses = questionResponses
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: QuestionIDCodingKeys.self)

        try self.questionResponses.forEach { (key: String, response: QuestionResponse) in
            guard let questionIDCodingKey = QuestionIDCodingKeys.init(stringValue: key) else {
                apptentiveCriticalError("Should always be able to create a QuestionIDCodingKeys instance with a string")
                throw ApptentiveError.internalInconsistency
            }

            var questionContainer = container.nestedContainer(keyedBy: QuestionResponseCodingKeys.self, forKey: questionIDCodingKey)

            switch response {
            case .answered(let answers):
                try questionContainer.encode(State.answered, forKey: .state)

                var valueContainer = questionContainer.nestedUnkeyedContainer(forKey: .value)
                for answer in answers {
                    var questionResponseContainer = valueContainer.nestedContainer(keyedBy: ChoiceCodingKeys.self)

                    switch answer {
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

            case .empty:
                try questionContainer.encode(State.empty, forKey: .state)

            case .skipped:
                try questionContainer.encode(State.skipped, forKey: .state)
            }
        }
    }

    init(from decoder: Decoder) throws {
        var keyedQuestionResponses = [String: QuestionResponse]()

        let container = try decoder.container(keyedBy: QuestionIDCodingKeys.self)

        for questionIDCodingKey in container.allKeys {
            if var v11questionContainer = try? container.nestedUnkeyedContainer(forKey: questionIDCodingKey) {
                keyedQuestionResponses[questionIDCodingKey.stringValue] = .answered(try Self.decodeAnswerArray(from: &v11questionContainer))
            } else {
                let v12questionContainer = try container.nestedContainer(keyedBy: QuestionResponseCodingKeys.self, forKey: questionIDCodingKey)
                let state = try v12questionContainer.decode(State.self, forKey: .state)

                keyedQuestionResponses[questionIDCodingKey.stringValue] = try {
                    switch state {
                    case .answered:
                        var answersContainer = try v12questionContainer.nestedUnkeyedContainer(forKey: .value)

                        return .answered(try Self.decodeAnswerArray(from: &answersContainer))

                    case .skipped:
                        return .skipped

                    case .empty:
                        return .empty
                    }
                }()
            }
        }

        self.questionResponses = keyedQuestionResponses
    }

    static func decodeAnswerArray(from container: inout UnkeyedDecodingContainer) throws -> [Answer] {
        var questionResponses = [Answer]()

        while !container.isAtEnd {
            let responseContainer = try container.nestedContainer(keyedBy: ChoiceCodingKeys.self)

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

        return questionResponses
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

    enum QuestionResponseCodingKeys: String, CodingKey {
        case state
        case value
    }

    enum State: String, Codable {
        case answered
        case empty
        case skipped
    }
}
