//
//  Criteria+Logging.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

extension EngagementManifest.Invocation {
    func evaluateWithLogging(for state: TargetingState) throws -> Bool {
        Logger.targeting.info("Evaluating criteria for interaction with identifier \(self.interactionID):")
        let result = try CriteriaLogging.$indentationLevel.withValue(1) {
            try self.criteria.isSatisfied(for: state)
        }
        Logger.targeting.info("Criteria are\(result ? " " : " not ")met.")
        return result
    }
}

extension ImplicitAndClause {
    var shouldLog: Bool {
        return self.subClauses.count > 1
    }

    func withLogging(evaluating operation: () throws -> Bool) rethrows -> Bool {
        guard self.shouldLog else { return try operation() }
        Logger.targeting.debug("\(CriteriaLogging.prefix)AND (all are true) [")
        let result = try CriteriaLogging.$indentationLevel.withValue(CriteriaLogging.indentationLevel + 1) {
            try operation()
        }
        Logger.targeting.debug("\(CriteriaLogging.prefix)] is \(result).")
        return result
    }
}

extension LogicalClause {
    var shouldLog: Bool {
        return self.subClauses.count > 1 || self.logicalOperator == .not
    }

    func withLogging(evaluating operation: () throws -> Bool) rethrows -> Bool {
        guard self.shouldLog else { return try operation() }
        if self.subClauses.count > 10 {
            Logger.targeting.debug("\(CriteriaLogging.prefix)\(self.logicalOperator.rawValue): evaluating \(self.subClauses.count) subclauses")
            let result = try CriteriaLogging.$suppressDetailedLogging.withValue(true) {
                try operation()
            }
            Logger.targeting.debug("\(CriteriaLogging.prefix)result is \(result).")
            return result
        } else {
            Logger.targeting.debug("\(CriteriaLogging.prefix)\(self.logicalOperator.rawValue) [")
            let result = try CriteriaLogging.$indentationLevel.withValue(CriteriaLogging.indentationLevel + 1) {
                try operation()
            }
            Logger.targeting.debug("\(CriteriaLogging.prefix)] is \(result).")
            return result
        }
    }
}

extension ConditionalClause {
    var shouldLog: Bool {
        return self.conditionalTests.count > 1
    }

    func withLogging(evaluating operation: () throws -> Bool) rethrows -> Bool {
        guard self.shouldLog else { return try operation() }
        Logger.targeting.debug("\(CriteriaLogging.prefix)AND (all are true) [")
        let result = try CriteriaLogging.$indentationLevel.withValue(CriteriaLogging.indentationLevel + 1) {
            try operation()
        }
        Logger.targeting.debug("\(CriteriaLogging.prefix)] is \(result).")
        return result
    }
}

extension ConditionalTest {
    func log(field: Field, value: Any?, result: Bool) {
        guard !CriteriaLogging.suppressDetailedLogging else { return }
        Logger.targeting.debug("\(CriteriaLogging.prefix)Comparison “\(field.fullPath) (\(String(describing: value))) \(conditionalOperator.rawValue) \(String(describing: parameter))” is \(result).")
    }
}

extension LogicalOperator: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .and:
            return "AND (all are true)"

        case .or:
            return "OR (any are true)"

        case .not:
            return "NOT (all are false)"
        }
    }
}

extension ConditionalOperator: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .exists:
            return "existence is"

        case .notEquals:
            return "is not equal to"

        case .equals:
            return "is equal to"

        case .lessThanOrEqual:
            return "is less than or equal to"

        case .lessThan:
            return "is less than"

        case .greaterThan:
            return "is greater than"

        case .greaterThanOrEqual:
            return "is greater than or equal to"

        case .startsWith:
            return "starts with"

        case .endsWith:
            return "ends with"

        case .contains:
            return "contains"

        case .before:
            return "is before"

        case .after:
            return "is after"

        }
    }
}

enum CriteriaLogging {
    @TaskLocal static var indentationLevel: Int = 0
    @TaskLocal static var suppressDetailedLogging: Bool = false

    static var prefix: String {
        String(repeating: " ", count: 2 * indentationLevel)
    }
}
