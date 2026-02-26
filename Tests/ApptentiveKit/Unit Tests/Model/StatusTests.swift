//
//  StatusTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 10/6/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct StatusTests {
    @Test func testDecoding() throws {
        let json = """
             {
                "last_update": 1759491198654,
                "message_center": {
                   "fg_poll": 10,
                   "bg_poll": 300
                },
                "hibernate_until": 1759491198654,
                "metrics_enabled": true
             }
            """

        let data = json.data(using: .utf8)!

        let status = try JSONDecoder.apptentive.decode(Status.self, from: data)

        #expect(status.lastUpdate == Date(timeIntervalSince1970: 1_759_491_198_654))
        #expect(status.hibernateUntil == Date(timeIntervalSince1970: 1_759_491_198_654))
        #expect(status.metricsEnabled)

        #expect(status.messageCenter.foregroundPollingInterval == 10)
        #expect(status.messageCenter.backgroundPollingInterval == 300)
    }
}
