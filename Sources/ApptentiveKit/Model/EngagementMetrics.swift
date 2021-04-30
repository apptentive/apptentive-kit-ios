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
    mutating func invoke(for key: String) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.invoke()
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

/// Records the number of invocations for the current version, current build, and all time, along with the date of the last invocation.
struct EngagementMetric: Equatable, Codable {
    init(totalCount: Int = 0, versionCount: Int = 0, buildCount: Int = 0, lastInvoked: Date? = nil) {
        self.totalCount = totalCount
        self.versionCount = versionCount
        self.buildCount = buildCount
        self.lastInvoked = lastInvoked
    }

    /// The total number of invocations.
    private(set) var totalCount: Int = 0

    /// The number of invocations since the current version of the app was installed.
    private(set) var versionCount: Int = 0

    /// The number of invocations since the current build of the app was installed.
    private(set) var buildCount: Int = 0

    /// The date of the last invocation.
    private(set) var lastInvoked: Date? = nil

    /// Resets the count for the current version of the app.
    mutating func resetVersion() {
        self.versionCount = 0
    }

    /// Resets the count for the current build of the app.
    mutating func resetBuild() {
        self.buildCount = 0
    }

    /// Increments all counts and resets the last invocation date to now.
    mutating func invoke() {
        self.totalCount += 1
        self.versionCount += 1
        self.buildCount += 1
        self.lastInvoked = Date()
    }

    /// Adds the counts from the newer object to the current one, and uses the newer of the two last invocation dates.
    /// - Parameter newer: The newer object to add to this one.
    /// - Returns: An object containing the sum of the current and newer metrics and last invocation date.
    func adding(_ newer: EngagementMetric) -> EngagementMetric {
        let newTotalCount = totalCount + newer.totalCount
        let newVersionCount = versionCount + newer.versionCount
        let newBuildCount = buildCount + newer.buildCount

        var newLastInvoked: Date? = nil
        if let lastInvoked = lastInvoked, let newerLastInvoked = newer.lastInvoked {
            newLastInvoked = max(lastInvoked, newerLastInvoked)
        } else {
            newLastInvoked = lastInvoked ?? newer.lastInvoked
        }

        return EngagementMetric(totalCount: newTotalCount, versionCount: newVersionCount, buildCount: newBuildCount, lastInvoked: newLastInvoked)
    }
}
