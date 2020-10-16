//
//  Criteria.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol CriteriaClause {
    func isSatisfied(for state: TargetingState) throws -> Bool
}

struct ImplicitAndClause: CriteriaClause {
    let subClauses: [CriteriaClause]

    func isSatisfied(for state: TargetingState) throws -> Bool {
        try subClauses.allSatisfy { try $0.isSatisfied(for: state) }
    }
}

typealias Criteria = ImplicitAndClause

struct LogicalClause: CriteriaClause {
    let logicalOperator: LogicalOperator
    let subClauses: [CriteriaClause]

    func isSatisfied(for state: TargetingState) throws -> Bool {
        try logicalOperator.evaluate(subClauses, for: state)
    }
}

struct ConditionalClause: CriteriaClause {
    let field: Field
    let conditionalTests: [ConditionalTest]

    func isSatisfied(for state: TargetingState) throws -> Bool {
        return try conditionalTests.allSatisfy { try $0.isSatisfied(for: field, of: state) }
    }
}

struct ConditionalTest {
    let conditionalOperator: ConditionalOperator
    let parameter: AnyObject?

    func isSatisfied(for field: Field, of state: TargetingState) throws -> Bool {
        return try conditionalOperator.evaluate(try state.value(for: field), with: parameter)
    }
}

enum LogicalOperator: String {
    case and = "$and"
    case or = "$or"
    case not = "$not"

    func evaluate(_ subClauses: [CriteriaClause], for state: TargetingState) throws -> Bool {
        switch self {
        case .and:
            return try subClauses.allSatisfy { try $0.isSatisfied(for: state) }
        case .or:
            return try subClauses.contains { try $0.isSatisfied(for: state) }
        case .not:  // Implemented as NAND, due to implicit AND of subclause collection
            return try !subClauses.allSatisfy { try $0.isSatisfied(for: state) }
        }
    }
}

enum ConditionalOperator: String {
    case exists = "$exists"
    case notEquals = "$ne"
    case equals = "$eq"
    case lessThanOrEqual = "$lte"
    case lessThan = "$lt"
    case greaterThan = "$gt"
    case greaterThanOrEqual = "$gte"
    case startsWith = "$starts_with"
    case endsWith = "$ends_with"
    case contains = "$contains"
    case before = "$before"
    case after = "$after"

    func evaluate(_ value: Any?, with parameter: AnyObject?) throws -> Bool {
        switch (self, value, parameter) {

        // Universal operators
        case (.exists, let value, let parameter as Bool):
            return (value != nil) == parameter

        // String operators
        case (.startsWith, let value as String, let parameter as String):
            return value.trimmedAndLowercased().hasPrefix(parameter.trimmedAndLowercased())
        case (.endsWith, let value as String, let parameter as String):
            return value.trimmedAndLowercased().hasSuffix(parameter.trimmedAndLowercased())
        case (.contains, let value as String, let parameter as String):
            return value.trimmedAndLowercased().contains(parameter.trimmedAndLowercased())

        // Relative date operators
        case (.after, let value as Date, let parameter as TimeInterval):
            return value > Date(timeIntervalSinceNow: parameter)
        case (.before, let value as Date, let parameter as TimeInterval):
            return value < Date(timeIntervalSinceNow: parameter)

        // Equality operators
        case (.equals, let value as Bool, let parameter as Bool):
            return value == parameter
        case (.equals, let value as String, let parameter as String):
            return value.trimmedAndLowercased() == parameter.trimmedAndLowercased()
        case (.equals, _ as Date, _ as Date):
            return false
        case (.equals, nil, nil):
            return true

        // Nonequality operators
        case (.notEquals, let value as Bool, let parameter as Bool):
            return value != parameter
        case (.notEquals, let value as String, let parameter as String):
            return value.trimmedAndLowercased() != parameter.trimmedAndLowercased()
        case (.notEquals, _ as Date, _ as Date):
            return false
        case (.notEquals, nil, nil):
            return false

        // Comparison operators
        case (_, _ as Bool, _ as Int):
            return false
        case (_, let value as Float, let parameter as Float):
            return compare(value, with: parameter)
        case (_, let value as Int, let parameter as Int):
            return compare(value, with: parameter)
        case (_, let value as Date, let parameter as Date):
            return compare(value, with: parameter)
        case (_, let value as Version, let parameter as Version):
            return compare(value, with: parameter)

        // Error cases
        default:
            return false
        }
    }

    func compare<T: Comparable>(_ value: T, with parameter: T) -> Bool {
        switch self {
        case .equals:
            return value == parameter
        case .notEquals:
            return value != parameter
        case .lessThanOrEqual:
            return value <= parameter
        case .lessThan:
            return value < parameter
        case .greaterThan:
            return value > parameter
        case .greaterThanOrEqual:
            return value >= parameter
        default:
            return false
        }
    }
}

extension String {
    fileprivate func trimmedAndLowercased() -> String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum TargetingError: Error {
    case unexpectedEndOfField(String, Int)
    case unrecognizedField(String)
    case unhandledConditionalTestCase(ConditionalOperator, Any?, AnyObject?)
}
