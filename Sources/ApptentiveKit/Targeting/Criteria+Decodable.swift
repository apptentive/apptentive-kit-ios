//
//  Criteria+Decodable.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/30/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

extension ImplicitAndClause: Decodable {
    init(from decoder: Decoder) throws {
        self.subClauses = try decodeKeyedSubClauses(from: decoder)
    }
}

extension LogicalClause: Decodable {
    init(from decoder: Decoder) throws {
        guard let parentKey = decoder.codingPath.last, let logicalOperator = LogicalOperator(rawValue: parentKey.stringValue) else {
            throw CriteriaDecodingError.unrecognizedLogicalOperator
        }

        self.logicalOperator = logicalOperator
        self.subClauses = try decodeUnkeyedSubClauses(from: decoder)
    }
}

extension ConditionalClause: Decodable {
    init(from decoder: Decoder) throws {
        guard let parentKey = decoder.codingPath.last?.stringValue else {
            throw CriteriaDecodingError.internalInconsistency
        }

        self.field = try Field(string: parentKey)

        if let container = try? decoder.container(keyedBy: ComplexParameterCodingKeys.self), let complexParameter = try? decodeComplexParameter(from: container) {
            // Shorthand version of a single equality test, e.g. `{ ..., "path/to/field": "parameter", ... }`
            // (with complex parameter, e.g. time or version)
            self.conditionalTests = [ConditionalTest(parameter: complexParameter)]
        } else if let container = try? decoder.container(keyedBy: CriteriaCodingKeys.self) {
            self.conditionalTests = try container.allKeys.map { key in
                return try container.decode(ConditionalTest.self, forKey: key)
            }
        } else if let container = try? decoder.singleValueContainer() {
            // Shorthand version of a single equality test, e.g. `{ ..., "path/to/field": "parameter", ... }`
            self.conditionalTests = [try ConditionalTest(parameter: decodeSimpleParameter(from: container))]
        } else {
            throw CriteriaDecodingError.invalidConditionalClause
        }
    }
}

extension ConditionalTest: Decodable {
    init(parameter: CriteriaParameter?) {
        self.conditionalOperator = .equals
        self.parameter = parameter
    }

    init(from decoder: Decoder) throws {
        guard let parentKey = decoder.codingPath.last else {
            throw CriteriaDecodingError.unrecognizedConditionalOperator
        }

        guard let conditionalOperator = ConditionalOperator(rawValue: parentKey.stringValue) else {
            throw CriteriaDecodingError.unrecognizedConditionalOperator
        }

        self.conditionalOperator = conditionalOperator

        if let container = try? decoder.container(keyedBy: ComplexParameterCodingKeys.self) {
            self.parameter = try decodeComplexParameter(from: container)
        } else if let container = try? decoder.singleValueContainer() {
            self.parameter = try decodeSimpleParameter(from: container)
        } else {
            throw CriteriaDecodingError.invalidConditionalTest
        }
    }
}

private func decodeKeyedSubClauses(from decoder: Decoder) throws -> [CriteriaClause] {
    let container = try decoder.container(keyedBy: CriteriaCodingKeys.self)

    return try container.allKeys.map { key in
        if key.stringValue.hasPrefix("$") {
            return try container.decode(LogicalClause.self, forKey: key)
        } else {
            return try container.decode(ConditionalClause.self, forKey: key)
        }
    }
}

private func decodeUnkeyedSubClauses(from decoder: Decoder) throws -> [CriteriaClause] {
    var container = try decoder.unkeyedContainer()
    var subClauses = [CriteriaClause]()

    while !container.isAtEnd {
        subClauses.append(try container.decode(ImplicitAndClause.self))
    }

    return subClauses
}

private func decodeSimpleParameter(from container: SingleValueDecodingContainer) throws -> CriteriaParameter? {
    if let int = try? container.decode(Int.self) {
        return int
    } else if let double = try? container.decode(Double.self) {
        return double
    } else if let bool = try? container.decode(Bool.self) {
        return bool
    } else if let string = try? container.decode(String.self) {
        return string
    } else if container.decodeNil() {
        return nil
    } else {
        throw CriteriaDecodingError.invalidSimpleParameter
    }
}

private func decodeComplexParameter(from container: KeyedDecodingContainer<ComplexParameterCodingKeys>) throws -> CriteriaParameter? {
    guard let type: ComplexParameterType = try? container.decode(ComplexParameterType.self, forKey: .type) else {
        throw CriteriaDecodingError.invalidComplexParameter
    }

    switch type {
    case .datetime:
        let secondsSince1970 = try container.decode(Double.self, forKey: .seconds)
        return Date(timeIntervalSince1970: secondsSince1970)
    case .version:
        let versionString = try container.decode(String.self, forKey: .version)
        return Version(string: versionString)
    }
}

private struct CriteriaCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }

    static func key(for string: String) throws -> Self {
        guard let key = CriteriaCodingKeys(stringValue: string) else {
            throw CriteriaDecodingError.internalInconsistency
        }

        return key
    }
}

private enum ComplexParameterCodingKeys: String, CodingKey {
    case seconds = "sec"
    case version
    case type = "_type"
}

private enum ComplexParameterType: String, Decodable {
    case datetime
    case version
}

enum CriteriaDecodingError: Error {
    case internalInconsistency
    case unrecognizedLogicalOperator
    case unrecognizedConditionalOperator
    case unrecognizedComplexParameter
    case invalidSimpleParameter
    case invalidComplexParameter
    case invalidConditionalClause
    case invalidConditionalTest
}
