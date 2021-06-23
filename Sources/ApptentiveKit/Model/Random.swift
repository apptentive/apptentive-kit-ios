//
//  Random.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Stores values used in random sampling
///
/// This needs to be a class because 
class Random: Equatable, Codable {
    var values: [String: Double]

    init() {
        self.values = [String: Double]()
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

    func randomPercent(for key: String) -> Double {
        return self.randomValue(for: key) * 100.0
    }

    func newRandomPercent() -> Double {
        return self.newRandomValue() * 100.0
    }

    static func == (lhs: Random, rhs: Random) -> Bool {
        lhs.values == rhs.values
    }

    private func randomValue(for key: String) -> Double {
        let result = self.values[key] ?? self.newRandomValue()

        self.values[key] = result

        return result
    }

    private func newRandomValue() -> Double {
        #if DEBUG
        return 0.5
        #else
        return Double.random(in: 0..<1)
        #endif
    }
}
