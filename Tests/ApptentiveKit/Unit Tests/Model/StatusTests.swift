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
                "sdk_enabled": true,
                "metrics_enabled": true, 
                "per_session_interaction_limit": 2,
             }
            """

        let data = json.data(using: .utf8)!

        let status = try JSONDecoder.apptentive.decode(Status.self, from: data)

        #expect(status.lastUpdate == Date(timeIntervalSince1970: 1_759_491_198_654))
        #expect(status.sdkEnabled == true)
        #expect(status.metricsEnabled)
        #expect(status.perSessionInteractionLimit == 2)
        #expect(status.messageCenter.foregroundPollingInterval == 10)
        #expect(status.messageCenter.backgroundPollingInterval == 300)
    }
}
