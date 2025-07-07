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
    func preLog() {
        CriteriaLogPrefix.shared.reset()
        Logger.targeting.info("Evaluating criteria for interaction with identifier \(self.interactionID):")
        CriteriaLogPrefix.shared.indent()
    }

    func postLog(_ result: Bool) {
        CriteriaLogPrefix.shared.outdent()
        Logger.targeting.info("Criteria are\(result ? " " : " not ")met.")
    }
}

extension ImplicitAndClause {
    var shouldLog: Bool {
        return self.subClauses.count > 1
    }

    func preLog() {
        if self.shouldLog {
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)AND (all are true) [")
            CriteriaLogPrefix.shared.indent()
        }
    }

    func postLog(_ result: Bool) {
        if self.shouldLog {
            CriteriaLogPrefix.shared.outdent()
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)] is \(result).")
        }
    }
}

extension LogicalClause {
    var shouldLog: Bool {
        return self.subClauses.count > 1 || self.logicalOperator == .not
    }

    func preLog() {
        if self.shouldLog {
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)\(self.logicalOperator.rawValue) [")
            CriteriaLogPrefix.shared.indent()
        }
    }

    func postLog(_ result: Bool) {
        if self.shouldLog {
            CriteriaLogPrefix.shared.outdent()
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)] is \(result).")
        }
    }
}

extension ConditionalClause {
    var shouldLog: Bool {
        return self.conditionalTests.count > 1
    }

    func preLog() {
        if self.shouldLog {
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)AND (all are true) [")
            CriteriaLogPrefix.shared.indent()
        }
    }

    func postLog(_ result: Bool) {
        if self.shouldLog {
            CriteriaLogPrefix.shared.outdent()
            Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)] is \(result).")
        }
    }
}

extension ConditionalTest {
    func log(field: Field, value: Any?, result: Bool) {
        Logger.targeting.debug("\(CriteriaLogPrefix.shared.stringValue)Comparison “\(field.fullPath) (\(String(describing: value))) \(conditionalOperator.rawValue) \(String(describing: parameter))” is \(result).")
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

struct CriteriaLogPrefix {
    // This will only ever be accessed by the targeting system, which
    // is entirely running in the Backend actor's isolation context.
    nonisolated(unsafe) static var shared = CriteriaLogPrefix()

    var stringValue: String {
        return String(repeating: " ", count: 2 * self.indentationLevel)
    }

    mutating func indent() {
        self.indentationLevel += 1
    }

    mutating func outdent() {
        self.indentationLevel -= 1

        if self.indentationLevel < 0 {
            apptentiveCriticalError("Over out-denting criteria log.")
            self.reset()
        }
    }

    mutating func reset() {
        self.indentationLevel = 0
    }

    private var indentationLevel: Int = 0
}
