//
//  EngagementMetrics.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents a keyed collection of `EngagementMetric` objects.
struct EngagementMetrics: Equatable, Codable {

    /// The internal collection of engagement metrics.
    var metrics: [String: EngagementMetric]

    /// Creates a new empty object.
    init() {
        self.metrics = [:]
    }

    /// Calls `invoke` on the specified engagement metric.
    ///
    /// If no engagement metric exists for the specified key, one will be created.
    /// - Parameter key: The key corresponding to the engagement metric to be invoked.
    mutating func invoke(for key: String, with answers: [Answer] = []) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.invoke(with: answers)
        self.metrics[key] = metric
    }

    /// Resets the version count for all metrics.
    mutating func resetBuild() {
        self.metrics.keys.forEach { (key) in
            self.metrics[key]?.resetBuild()
        }
    }

    /// Resets the build count for all metrics.
    mutating func resetVersion() {
        self.metrics.keys.forEach { (key) in
            self.metrics[key]?.resetVersion()
        }
    }

    /// Merges this object with a newer object.
    ///
    /// This will sum the newer and current object counts.
    /// - Parameter newer: The newer object to merge with this one.
    mutating func merge(with newer: EngagementMetrics) {
        self.metrics = metrics.merging(newer.metrics) { (old, new) in
            old.adding(new)
        }
    }

    subscript(key: String) -> EngagementMetric? {
        get {
            return self.metrics[key]
        }
        set {
            self.metrics[key] = newValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try self.metrics.forEach { (key, value) in
            try container.encode(self.metrics[key], forKey: try CodingKeys.key(for: key))
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.metrics = [:]

        try container.allKeys.forEach { key in
            self.metrics[key.stringValue] = try container.decode(EngagementMetric.self, forKey: key)
        }
    }

    struct CodingKeys: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.stringValue = String(intValue)
        }

        static func key(for string: String) throws -> Self {
            guard let key = Self(stringValue: string) else {
                throw ApptentiveError.internalInconsistency
            }

            return key
        }
    }
}
