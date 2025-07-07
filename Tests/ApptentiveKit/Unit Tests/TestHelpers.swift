//
//  TestHelpers.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/20/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

class BundleFinder {}

struct TestError: Error {
    let reason: String?
}

// from: https://github.com/swiftlang/swift-testing/blob/9c4583773bd5ce4baa82c843c0727a6e65218c6d/Sources/Testing/Issues/FloatingPointAccuracy.swift

// MARK: - Abstract operator definitions

/// The precedence group used by the `±` operator.
///
/// This precedence group allows for expressions like `(1.0 == 2.0) ± 5.0`.
precedencegroup AccuracyPrecedence {
    associativity: left
    lowerThan: AssignmentPrecedence
}

/// The `±` operator.
///
/// This operator allows for expressions like `(1.0 == 2.0) ± 5.0`.
infix operator ± : AccuracyPrecedence

/// The `+-` operator.
///
/// This operator allows for expressions like `(1.0 == 2.0) ± 5.0`. It is a
/// replacement for `±` that can be used when that character is unavailable or
/// difficult to type.
infix operator +- : AccuracyPrecedence

// MARK: - Storage for operands

@frozen public struct FloatingPointComparison<F> where F: FloatingPoint {
    @usableFromInline var lhs: F
    @usableFromInline var rhs: F

    @usableFromInline enum Operator: Sendable {
        case equals
        case doesNotEqual
    }
    @usableFromInline var `operator`: Operator

    @usableFromInline init(lhs: F, rhs: F, operator: Operator) {
        self.lhs = lhs
        self.rhs = rhs
        self.operator = `operator`
    }

    @usableFromInline func callAsFunction(accuracy: F) -> Bool {
        let diff = (lhs - rhs).magnitude
        return switch `operator` {
        case .equals:
            diff <= accuracy
        case .doesNotEqual:
            diff > accuracy
        }
    }
}

// Helper function for timeout
func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @Sendable @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        // Add the actual operation
        group.addTask {
            return try await operation()
        }

        // Add a timeout task
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds) * NSEC_PER_SEC)
            throw TimeoutError(seconds: seconds)
        }

        // Return the first completed task result, or throw if both fail
        let result = try await group.next()!
        // Cancel any remaining tasks
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error {
    let seconds: TimeInterval
    var localizedDescription: String {
        return "Operation timed out after \(seconds) seconds"
    }
}

@available(*, unavailable)
extension FloatingPointComparison: Sendable {}

extension FloatingPointComparison: CustomTestStringConvertible {
    public var testDescription: String {
        switch `operator` {
        case .equals:
            "(\(lhs) == \(rhs))"
        case .doesNotEqual:
            "(\(lhs) != \(rhs))"
        }
    }
}

// MARK: - Comparison operator overloads

@_disfavoredOverload
@inlinable public func == <F>(_lhs: F, rhs: F) -> FloatingPointComparison<F> where F: FloatingPoint {
    FloatingPointComparison(lhs: _lhs, rhs: rhs, operator: .equals)
}

@_disfavoredOverload
@inlinable public func != <F>(_lhs: F, rhs: F) -> FloatingPointComparison<F> where F: FloatingPoint {
    FloatingPointComparison(lhs: _lhs, rhs: rhs, operator: .doesNotEqual)
}

// MARK: - Accuracy operators

/// The `±` operator.
///
/// This operator allows for expressions like `(1.0 == 2.0) ± 5.0`. Use it when
/// comparing floating-point values that may have accumulated error:
///
/// ```swift
/// let totalOrderCost = allFoods.reduce(into: 0.0, +=)
/// #expect(totalOrderCost == 100.00 ± 0.01)
/// ```
///
/// This operator can be used after the `==` and `!=` operators to compare two
/// floating-point values of the same type. It can also be spelled `+-` (the two
/// spellings are exactly equivalent.)
@inlinable public func ± <F>(comparison: FloatingPointComparison<F>, accuracy: F) -> Bool where F: FloatingPoint {
    comparison(accuracy: accuracy)
}

/// The `+-` operator.
///
/// This operator allows for expressions like `(1.0 == 2.0) ± 5.0`. It is a
/// replacement for `±` that can be used when that character is unavailable or
/// difficult to type.
@inlinable public func +- <F>(_comparison: FloatingPointComparison<F>, accuracy: F) -> Bool where F: FloatingPoint {
    _comparison(accuracy: accuracy)
}
