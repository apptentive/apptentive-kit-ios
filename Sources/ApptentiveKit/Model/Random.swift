//
//  Random.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Stores values used in random sampling.
///
/// The random values are generated on demand, deep inside a function call stack,
/// so propagating the values back up to the canonical `Conversation` object
/// would be tricky.
///
/// For that reason we make this object a class so that it has reference semantics.
class Random: Equatable, Codable {
    var values: [String: Float]

    init() {
        self.values = [String: Float]()
    }

    /// Merges the custom data with newer custom data.
    /// - Parameter newer: The newer custom data to merge in.
    func merge(with newer: Random) {
        if self === newer {
            return
        }

        self.values.merge(newer.values) { old, new in
            old + new
        }
    }

    func randomPercent(for key: String) -> Float {
        return self.randomValue(for: key) * 100.0
    }

    func newRandomPercent() -> Float {
        return self.newRandomValue() * 100.0
    }

    static func == (lhs: Random, rhs: Random) -> Bool {
        lhs.values == rhs.values
    }

    private func randomValue(for key: String) -> Float {
        let result = self.values[key] ?? self.newRandomValue()

        self.values[key] = result

        return result
    }

    private func newRandomValue() -> Float {
        #if DEBUG
            return 0.5
        #else
            return Float.random(in: 0..<1)
        #endif
    }
}
