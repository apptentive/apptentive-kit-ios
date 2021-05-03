//
//  LegacyConversationRepositoryTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class LegacyConversationRepositoryTests: XCTestCase {
    var conversation: Conversation?

    override func setUpWithError() throws {
        guard let containerURL = Bundle(for: Self.self).url(forResource: "Legacy Data", withExtension: "") else {
            throw TestError()
        }

        let repository = LegacyConversationRepository(containerURL: containerURL, filename: "conversation-v1.meta", environment: MockEnvironment())

        self.conversation = try repository.load()
    }

    func testConversationCredentials() throws {
        XCTAssertEqual(
            self.conversation?.conversationCredentials?.token,
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MDhiM2I4MTEyNjBmNjZmMmMwZjY5ZDMiLCJhcHBfaWQiOiI1NWYzMWJjZDIyNTcwZWIxNDYwMDAwMzIiLCJpYXQiOjE2MTk3Mzc0NzN9.CR4vqdkXi1FQAHHttM0hRV8XMXjU2h35Ztg9B7y39BGNZK7Z9xx_i-UlX1rmEtbmJ9W03Qs21mloE3DX48ghyg"
        )

        XCTAssertEqual(self.conversation?.conversationCredentials?.id, "608b3b811260f66f2c0f69d3")
    }

    func testEngagementMetrics() throws {
        XCTAssertNotEqual(self.conversation?.codePoints.metrics.keys.count, 0)

        XCTAssertNotEqual(self.conversation?.interactions.metrics.keys.count, 0)
    }
}

struct TestError: Error {}
