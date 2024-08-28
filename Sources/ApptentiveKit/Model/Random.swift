//
//  Random.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import CryptoKit
import Foundation

/// Stores values used in random sampling.
///
/// Previously the random values were generated on demand, deep inside a function call stack,
/// so propagating the values back up to the canonical `Conversation` object
/// would have been tricky, and for that reason we made this object a class so that it had reference semantics.
///
/// That became problematic with the new Swift 6 concurrency requirements, because the class
/// was not Sendable.
///
/// The new approach is to generate a random seed when the object is first initialized
/// (or when it is decoded and the seed is absent).
///
/// When there is an existing entry in the `values` array, it is returned
/// for backward compatibility.
///
/// When a new random value is required, it computes an MD5 hash of the
/// combination of the key and the seed, takes the integer value of the first
/// two bytes, and normalizes it to a value between 0 and 100.
///
/// This should provide a value that is randomized both across different
/// `key`s as well as across different conversations.
struct Random: Equatable, Codable, Sendable {
    var values: [String: Double]  // Only used for pre-existing values.
    var seed: Int
    #if DEBUG
        let isDebug = true
    #else
        let isDebug = false
    #endif

    init() {
        self.values = [String: Double]()
        self.seed = Self.newRandomSeed()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.values = try container.decode([String: Double].self, forKey: .values)
        self.seed = try container.decodeIfPresent(Int.self, forKey: .seed) ?? Self.newRandomSeed()
    }

    /// Merges the random values with newer random values.
    /// - Parameter newer: The newer random values to merge in.
    mutating func merge(with newer: Random) {
        if self == newer {
            return
        }

        // Else keep the older seed and values.
    }

    func randomPercent(for key: String) -> Double {
        // If we previously used the stored-value method for this key, keep using it.
        if let result = self.values[key] {
            return result * 100  // Values were previously stored as between zero and 1
        } else {
            return Self.pseudoRandomValue(for: key, seed: self.seed, isDebug: self.isDebug)
        }
    }

    func newRandomPercent() -> Double {
        return Self.newRandomValue(isDebug: self.isDebug)
    }

    // MARK: - Private

    private static func pseudoRandomValue(for key: String, seed: Int, isDebug: Bool) -> Double {
        if isDebug {
            return 50
        } else {
            return Self.computePseudoRandomValue(for: key, seed: seed)
        }
    }

    private static func newRandomValue(isDebug: Bool) -> Double {
        if isDebug {
            return 50
        } else {
            return Double.random(in: 0..<100)
        }
    }

    // Using MD5 hash, which is massive overkill but suitably random and stable.
    // (String's hashValue will change each run, and basic hash calculations
    // don't seem to be random enough).
    private static func computePseudoRandomValue(for key: String, seed: Int) -> Double {
        var seedCopy = seed
        let keyData = Data(key.utf8)
        let seedData = withUnsafeBytes(of: &seedCopy) { Data($0) }
        let digest = Insecure.MD5.hash(data: keyData + seedData)
        let firstTwoBytes = Data(digest.prefix(2)).withUnsafeBytes { $0.load(as: UInt16.self) }

        return Double(firstTwoBytes) / 655.36
    }

    private static func newRandomSeed() -> Int {
        Int(Double.random(in: 0..<1_000_000))
    }
}
