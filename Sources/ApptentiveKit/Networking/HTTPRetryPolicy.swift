//
//  HTTPRetryPolicy.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct HTTPRetryPolicy {
    let initialDelay: Double
    let multiplier: Double
    let useJitter: Bool

    private var baseRetryDelay: TimeInterval

    internal init(initialDelay: Double = 5.0, multiplier: Double = 2.0, useJitter: Bool = true) {
        self.initialDelay = initialDelay
        self.multiplier = multiplier
        self.useJitter = useJitter

        self.baseRetryDelay = initialDelay
    }

    var retryDelay: TimeInterval {
        let jitter = self.useJitter ? Double.random(in: 0..<1) : 1
        return self.baseRetryDelay * jitter
    }

    func shouldRetry(inCaseOf error: HTTPClientError) -> Bool {
        switch error {
        case .connectionError, .serverError:
            return true

        default:
            return false
        }
    }

    mutating func incrementRetryDelay() {
        self.baseRetryDelay *= multiplier
    }

    mutating func resetRetryDelay() {
        self.baseRetryDelay = self.initialDelay
    }
}
