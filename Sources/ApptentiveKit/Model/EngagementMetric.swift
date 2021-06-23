//
//  EngagementMetric.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/12/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Records the number of invocations for the current version, current build, and all time, along with the date of the last invocation.
struct EngagementMetric: Equatable, Codable {
    init(totalCount: Int = 0, versionCount: Int = 0, buildCount: Int = 0, lastInvoked: Date? = nil, lastCompleted: Date? = nil, answers: [Answer] = []) {
        self.totalCount = totalCount
        self.versionCount = versionCount
        self.buildCount = buildCount
        self.lastInvoked = lastInvoked
        self.answers = answers
    }

    /// The total number of invocations.
    private(set) var totalCount: Int = 0

    /// The number of invocations since the current version of the app was installed.
    private(set) var versionCount: Int = 0

    /// The number of invocations since the current build of the app was installed.
    private(set) var buildCount: Int = 0

    /// The date of the last invocation.
    private(set) var lastInvoked: Date? = nil

    /// The answers associated with this metric.
    private(set) var answers: [Answer]

    /// Resets the count for the current version of the app.
    mutating func resetVersion() {
        self.versionCount = 0
    }

    /// Resets the count for the current build of the app.
    mutating func resetBuild() {
        self.buildCount = 0
    }

    /// Increments all counts and resets the last invocation date to now.
    mutating func invoke(with answers: [Answer] = []) {
        self.totalCount += 1
        self.versionCount += 1
        self.buildCount += 1
        self.lastInvoked = Date()
        self.answers += answers
    }

    /// Adds the counts from the newer object to the current one, and uses the newer of the two last invocation dates.
    /// - Parameter newer: The newer object to add to this one.
    /// - Returns: An object containing the sum of the current and newer metrics and last invocation date.
    func adding(_ newer: EngagementMetric) -> EngagementMetric {
        let newTotalCount = totalCount + newer.totalCount
        let newVersionCount = versionCount + newer.versionCount
        let newBuildCount = buildCount + newer.buildCount
        let newAnswers = answers + newer.answers

        var newLastInvoked: Date? = nil
        if let lastInvoked = lastInvoked, let newerLastInvoked = newer.lastInvoked {
            newLastInvoked = max(lastInvoked, newerLastInvoked)
        } else {
            newLastInvoked = lastInvoked ?? newer.lastInvoked
        }

        return EngagementMetric(totalCount: newTotalCount, versionCount: newVersionCount, buildCount: newBuildCount, lastInvoked: newLastInvoked, answers: newAnswers)
    }
}
