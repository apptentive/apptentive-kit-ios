//
//  StatusTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 10/28/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class StatusTests: XCTestCase {
    func testDecoding() throws {
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

        let configuration = try JSONDecoder.apptentive.decode(Status.self, from: data)

        XCTAssertEqual(configuration.lastUpdate, Date(timeIntervalSince1970: 1_759_491_198_654))
        XCTAssertEqual(configuration.hibernateUntil, Date(timeIntervalSince1970: 1_759_491_198_654))
        XCTAssertEqual(configuration.metricsEnabled, true)

        XCTAssertEqual(configuration.messageCenter.foregroundPollingInterval, 10)
        XCTAssertEqual(configuration.messageCenter.backgroundPollingInterval, 300)
    }
}
