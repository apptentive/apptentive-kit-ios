//
//  EngagementMetrics.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/26/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

// Want subscriptability
// Want to code this as a keyed container

struct EngagementMetrics: Equatable, Codable {
    var metrics: [String: EngagementMetric]

    init() {
        self.metrics = [:]
    }

    mutating func invoke(for key: String) {
        var metric = metrics[key] ?? EngagementMetric()
        metric.invoke()
        self.metrics[key] = metric
    }

    mutating func resetBuild() {
        self.metrics.keys.forEach { (key) in
            self.metrics[key]?.resetBuild()
        }
    }

    mutating func resetVersion() {
        self.metrics.keys.forEach { (key) in
            self.metrics[key]?.resetVersion()
        }
    }

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

struct EngagementMetric: Equatable, Codable {
    private(set) var totalCount: Int = 0
    private(set) var versionCount: Int = 0
    private(set) var buildCount: Int = 0
    private(set) var lastInvoked: Date? = nil

    mutating func resetVersion() {
        self.versionCount = 0
    }

    mutating func resetBuild() {
        self.buildCount = 0
    }

    mutating func invoke() {
        self.totalCount += 1
        self.versionCount += 1
        self.buildCount += 1
        self.lastInvoked = Date()
    }

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
