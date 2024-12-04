//
//  Criteria.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents the basic unit of criteria, a clause that evalutes to either true or false (or throws) based on the supplied state.
protocol CriteriaClause: Sendable {
    func isSatisfied(for state: TargetingState) throws -> Bool
}

/// The top-level clause of the criteria is a dictionary that represents an implicit AND operation for each key/value pair.
struct ImplicitAndClause: CriteriaClause {
    /// The clauses, one per key-value pair, present in the top-level criteria.
    let subClauses: [CriteriaClause]

    /// Whether the clause is satisfied for the provided state.
    /// - Parameter state: The targeting state (source of values for fields) to evaluate against.
    /// - Throws: An error in case of an invalid field.
    /// - Returns: Whether the clause is satisfied.
    func isSatisfied(for state: TargetingState) throws -> Bool {
        self.preLog()

        let result = try subClauses.allSatisfy { try $0.isSatisfied(for: state) }

        self.postLog(result)

        return result
    }
}

typealias Criteria = ImplicitAndClause

/// Represents a logical clause, that evaluates its subclauses using a boolean logical operator.
struct LogicalClause: CriteriaClause {
    /// The boolean operator to use to derive an overall result from the subclauses.
    let logicalOperator: LogicalOperator

    /// The clauses, one per key-value pair, contained in the logical clause.
    let subClauses: [CriteriaClause]

    /// Whether the clause is satisfied for the provided state.
    /// - Parameter state: The targeting state (source of values for fields) to evaluate the subclauses against.
    /// - Throws: An error in case of an invalid field.
    /// - Returns: Whether the clause is satisfied.
    func isSatisfied(for state: TargetingState) throws -> Bool {
        self.preLog()

        let result = try logicalOperator.evaluate(subClauses, for: state)

        self.postLog(result)

        return result
    }
}

/// Represents a conditional clause, including a field and one or more conditional tests.
struct ConditionalClause: CriteriaClause {
    /// The field whose value the criteria will be evaluated against.
    let field: Field

    /// The set of tests comparing the field value against parameters.
    let conditionalTests: [ConditionalTest]

    /// Whether the clause is satisfied for the provided state.
    /// - Parameter state: The targeting state (source of values for fields) to evaluate against.
    /// - Throws: An error in case of an invalid field.
    /// - Returns: Whether the clause is satisfied.
    func isSatisfied(for state: TargetingState) throws -> Bool {
        self.preLog()

        let result = try conditionalTests.allSatisfy { try $0.isSatisfied(for: field, of: state) }

        self.postLog(result)

        return result
    }
}

protocol CriteriaParameter: Sendable {}

extension Double: CriteriaParameter {}
extension Bool: CriteriaParameter {}
extension String: CriteriaParameter {}
extension Date: CriteriaParameter {}
extension Int: CriteriaParameter {}
extension Version: CriteriaParameter {}

/// Represents a conditional test, in which a parameter is evaluated using an operator against a field value.
struct ConditionalTest: Sendable {

    /// The operator to use when comparing the value to the parameter.
    let conditionalOperator: ConditionalOperator

    /// The parameter against which to compaire the value.
    let parameter: CriteriaParameter?

    /// Whether the test passes given the field and state.
    /// - Parameters:
    ///   - field: The field whose value will be compared.
    ///   - state: The provider of field values for comparison.
    /// - Throws: An error in case of an invalid field.
    /// - Returns: The result of the test.
    func isSatisfied(for field: Field, of state: TargetingState) throws -> Bool {
        var value: Any?
        do {
            value = try state.value(for: field)
        } catch {
            value = nil
            ApptentiveLogger.default.error("Error recognizing targeting field: \(error)")
        }
        let result = conditionalOperator.evaluate(value, with: parameter)

        self.log(field: field, value: value, result: result)

        return result
    }
}

/// Describes a logical operation on subclauses.
enum LogicalOperator: String {
    /// Operator that requires all subclauses to pass to make the clause pass.
    case and = "$and"

    /// Operator that requires at least one subclause to pass to make the clause pass.
    case or = "$or"

    /// Operator that requires all subclauses to *not* pass to make the clause pass.
    case not = "$not"

    /// Performs the logical operation with the supplied subclauses and state.
    /// - Parameters:
    ///   - subClauses: The subclauses to evaluate.
    ///   - state: The targeting state (source of values for fields) to evaluate the subclauses against.
    /// - Throws: An error in case of a type mismatch.
    /// - Returns: The result of the logical operation.
    func evaluate(_ subClauses: [CriteriaClause], for state: TargetingState) throws -> Bool {
        switch self {
        case .and:
            return try subClauses.allSatisfy { try $0.isSatisfied(for: state) }
        case .or:
            return try subClauses.contains { try $0.isSatisfied(for: state) }
        case .not:  // Implemented as NAND, due to implicit AND of subclause collection.
            return try !subClauses.allSatisfy { try $0.isSatisfied(for: state) }
        }
    }
}

/// An operator that compares a field's value against a parameter.
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

    /// Evaluates a field's value against a parameter.
    /// - Parameters:
    ///   - value: The value to be compared against the parameter.
    ///   - parameter: The parameter to be compared against the value.
    /// - Returns: The result of the operation.
    func evaluate(_ value: Any?, with parameter: CriteriaParameter?) -> Bool {
        switch (self, value, parameter) {

        // Existential set (interaction response) operators
        case (.exists, let value as Set<String>, let parameter as Bool):
            return value.isEmpty != parameter
        case (.exists, let value as Set<Answer.Value>, let parameter as Bool):
            return value.isEmpty != parameter

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

        // String set (interaction response) operators
        case (.startsWith, let value as Set<Answer.Value>, let parameter as String):
            return value.contains(where: { $0.stringValue?.trimmedAndLowercased().hasPrefix(parameter.trimmedAndLowercased()) == true })
        case (.endsWith, let value as Set<Answer.Value>, let parameter as String):
            return value.contains(where: { $0.stringValue?.trimmedAndLowercased().hasSuffix(parameter.trimmedAndLowercased()) == true })
        case (.contains, let value as Set<Answer.Value>, let parameter as String):
            return value.contains(where: { $0.stringValue?.trimmedAndLowercased().contains(parameter.trimmedAndLowercased()) == true })

        // Relative date operators
        case (.after, let value as Date, let parameter as TimeInterval):
            return value > Date(timeIntervalSinceNow: parameter)
        case (.before, let value as Date, let parameter as TimeInterval):
            return value < Date(timeIntervalSinceNow: parameter)
        case (.after, let value as Date, let parameter as Int):
            return value > Date(timeIntervalSinceNow: TimeInterval(parameter))
        case (.before, let value as Date, let parameter as Int):
            return value < Date(timeIntervalSinceNow: TimeInterval(parameter))

        // Equality operators
        case (.equals, let value as Bool, let parameter as Bool):
            return value == parameter
        case (.equals, let value as String, let parameter as String):
            return value.trimmedAndLowercased() == parameter.trimmedAndLowercased()
        case (.equals, _ as Date, _ as Date):
            return false
        case (.equals, nil, nil):
            return true

        // Equality set (interaction response) operators
        case (.equals, let value as Set<String>, let parameter as String):
            return value.contains(parameter)
        case (.equals, let value as Set<Answer.Value>, let parameter as String):
            return value.contains(where: { $0.stringValue?.trimmedAndLowercased() == parameter.trimmedAndLowercased() })
        case (.equals, let value as Set<Answer.Value>, let parameter as Int):
            return value.contains(where: { $0.intValue == parameter })

        // Nonequality operators
        case (.notEquals, let value as Bool, let parameter as Bool):
            return value != parameter
        case (.notEquals, let value as String, let parameter as String):
            return value.trimmedAndLowercased() != parameter.trimmedAndLowercased()
        case (.notEquals, _ as Date, _ as Date):
            return true
        case (.notEquals, nil, nil):
            return false
        case (.notEquals, nil, _):
            return true

        // Nonequality set (interaction response) operators
        case (.notEquals, let value as Set<String>, let parameter as String):
            return !value.contains(parameter)
        case (.notEquals, let value as Set<Answer.Value>, let parameter as String):
            return !value.contains(where: { $0.stringValue?.trimmedAndLowercased() == parameter.trimmedAndLowercased() })
        case (.notEquals, let value as Set<Answer.Value>, let parameter as Int):
            return !value.contains(where: { $0.intValue == parameter })

        // Comparison operators
        case (_, _ as Bool, _ as Int):
            return false
        case (_, let value as Double, let parameter as Double):
            return compare(value, with: parameter)
        case (_, let value as Int, let parameter as Double):
            return compare(Double(value), with: parameter)
        case (_, let value as Int, let parameter as Int):
            return compare(value, with: parameter)
        case (_, let value as Double, let parameter as Int):
            return compare(value, with: Double(parameter))
        case (_, let value as Date, let parameter as Date):
            return compare(value, with: parameter)
        case (_, let value as Version, let parameter as Version):
            return compare(value, with: parameter)

        // Comparison set (interaction response) operators
        case (_, let value as Set<Answer.Value>, let parameter as Int):
            return value.contains(where: { element in
                if let intValue = element.intValue {
                    return compare(intValue, with: parameter)
                } else {
                    return false
                }
            })

        // Error cases
        default:
            return false
        }
    }

    /// Compares two `Comparable` values according to this operator.
    /// - Parameters:
    ///   - value: The value to compare against the parameter.
    ///   - parameter: The parameter to compare against the value.
    /// - Returns: The result of the comparison.
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
    /// Trims whitespace from a string and converts it to lowercase.
    /// - Returns: A copy of the string that has been trimmed of whitespace and converted to lowercase.
    fileprivate func trimmedAndLowercased() -> String {
        return self.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Describes an error encountered when evaluating criteria.
enum TargetingError: Error {

    /// A field whose prefix suggests a suffix lacks that suffix.
    case unexpectedEndOfField(String, Int)

    /// This version of the SDK didn't recognize the field.
    case unrecognizedField(String)
}
