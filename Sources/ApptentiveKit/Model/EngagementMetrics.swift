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
    mutating func increment(for key: String) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.increment()
        self.metrics[key] = metric
    }

    /// Calls `record` on the specified engagement metric.
    ///
    /// If no engagement metric exists for the specified key, one will be created.
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - key: The key corresponding to the engagement metric for which to record the response.
    mutating func record(_ response: QuestionResponse, for key: String) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.record(response)
        self.metrics[key] = metric
    }

    /// Calls `setLastResponse` on the specified engagement metric.
    ///
    /// If no engagement metric exists for the specified key, one will be created.
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - key: The key corresponding to the engagement metric for which to record response.
    mutating func setLastResponse(_ response: QuestionResponse, for key: String) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.setCurrentResponse(response)
        self.metrics[key] = metric
    }

    /// Calls `ask` on the engagement metric if one exists for the specified key.
    /// - Parameter key: The key corresponding to the engagement metric for which to record having requested an answer.
    mutating func resetCurrentResponse(for key: String) {
        self.metrics[key]?.resetCurrentResponse()
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
