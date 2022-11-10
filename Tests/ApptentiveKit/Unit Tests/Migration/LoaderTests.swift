//
//  LoaderTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class LoaderTests: XCTestCase {
    override func setUpWithError() throws {
        try MockEnvironment.cleanContainerURL()

        super.setUp()
    }

    func testLegacyLoading() throws {
        guard let containerURL = Bundle(for: Self.self).url(forResource: "Legacy Data", withExtension: "") else {
            throw TestError()
        }

        let expectation = XCTestExpectation()

        CurrentLoader.loadLatestVersion(containerURL: containerURL, environment: MockEnvironment()) { loader in
            let conversation = try loader.loadConversation()
            let _ = try loader.loadPayloads()
            let _ = try loader.loadMessages()
            try loader.cleanUp()

            XCTAssertEqual(
                conversation.conversationCredentials?.token,
                "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MjI4ZjgwMTg5OTE1MTc1OGYwYmNjMDQiLCJhcHBfaWQiOiI1N2QzMzY3NzgyZTNiMmIzZTkwMDAwMDYiLCJpYXQiOjE2NDY4NTIwOTd9.4o5RNgIDs7k3WqVj3dUZtki39ceKt86KcGL8KaBUzYcZS8xwtya9cttQcj0MPDJJFxp_zJQog7vjJyvqcZLDFg"
            )

            XCTAssertEqual(conversation.conversationCredentials?.id, "6228f801899252758f0bcc04")

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
            XCTAssertNotEqual(conversation.interactions.metrics.keys.count, 0)

            XCTAssertEqual(conversation.person.name, "Testy")
            XCTAssertEqual(conversation.person.emailAddress, "testy@mctestface.com")

            XCTAssertEqual(conversation.person.customData["string"] as? String, "test")
            XCTAssertEqual(conversation.person.customData["number"] as? Int, 5)
            XCTAssertEqual(conversation.person.customData["bool"] as? Bool, true)

            XCTAssertEqual(conversation.device.customData["string"] as? String, "test2")
            XCTAssertEqual(conversation.device.customData["number"] as? Int, 42)
            XCTAssertEqual(conversation.device.customData["false"] as? Bool, false)

            XCTAssertEqual(conversation.random.values["60304f1a0efe7e7b44000003"], 0.5)
            XCTAssertEqual(conversation.random.values["6053f24391502521cf000014"], 0.5)

            expectation.fulfill()
        }

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))

        self.wait(for: [expectation], timeout: 5.0)
    }

    func testBeta3Loading() throws {
        guard let containerURL = Bundle(for: Self.self).url(forResource: "Beta3 Data", withExtension: "") else {
            throw TestError()
        }

        let expectation = XCTestExpectation()

        var hasRunClosureOnce = false
        CurrentLoader.loadLatestVersion(containerURL: containerURL, environment: MockEnvironment()) { loader in
            if hasRunClosureOnce {
                let conversation = try loader.loadConversation()
                let _ = try loader.loadPayloads()
                let _ = try loader.loadMessages()
                try loader.cleanUp()

                XCTAssertEqual(
                    conversation.conversationCredentials?.token,
                    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MDhiM2I4MTEyNjBmNjZmMmMwZjY5ZDMiLCJhcHBfaWQiOiI1NWYzMWJjZDIyNTcwZWIxNDYwMDAwMzIiLCJpYXQiOjE2MTk3Mzc0NzN9.CR4vqdkXi1FQAHHttM0hRV8XMXjU2h35Ztg9B7y39BGNZK7Z9xx_i-UlX1rmEtbmJ9W03Qs21mloE3DX48ghyf"
                )

                XCTAssertEqual(conversation.conversationCredentials?.id, "818b3b811260f66f2c0f69d3")

                XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
                XCTAssertNotEqual(conversation.interactions.metrics.keys.count, 0)

                expectation.fulfill()
            } else {
                XCTAssertThrowsError(try loader.loadConversation())
                XCTAssertThrowsError(try loader.loadMessages())
                XCTAssertThrowsError(try loader.loadPayloads())
                XCTAssertNoThrow(try loader.cleanUp())

                hasRunClosureOnce = true

                throw TestError()
            }
        }

        // Should delete the problematic files.
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Conversation.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("PayloadQueue.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("MessageList.plist").path))

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))

        self.wait(for: [expectation], timeout: 5.0)
    }

    func testCurrentLoading() throws {
        guard let containerURL = Bundle(for: Self.self).url(forResource: "Current Data", withExtension: "") else {
            throw TestError()
        }

        let expectation = XCTestExpectation()

        CurrentLoader.loadLatestVersion(containerURL: containerURL, environment: MockEnvironment()) { loader in
            let conversation = try loader.loadConversation()
            let _ = try loader.loadPayloads()
            let _ = try loader.loadMessages()
            try loader.cleanUp()

            XCTAssertEqual(
                conversation.conversationCredentials?.token,
                "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MTk1YWM1MzY3NTlhZDU0ODcwMGY1ZjEiLCJhcHBfaWQiOiI1ZjM1NzEyYjRhYmY5OTA0YjYwMDAwMWUiLCJpYXQiOjE2MzcxOTg5MzF9.ZKGv8JC1yK1CSFlovh6Cst1VY75jDw5RjKlxVGUEIaIPxMAgzND8j-yvh6OQU2zXPB2s8LEiosq3JeIDQDCH9f"
            )

            XCTAssertEqual(conversation.conversationCredentials?.id, "3605ac536759ad548700f5f1")

            expectation.fulfill()
        }

        // Should delete the problematic files.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Conversation.A.plist").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("PayloadQueue.A.plist").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("MessageList.A.plist").path))

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))

        self.wait(for: [expectation], timeout: 5.0)
    }
}

struct TestError: Error {}
