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
    let appCredentials = Apptentive.AppCredentials(key: "IOS-OPERATOR-redacted", signature: "redacted")
    let cacheURL = URL(fileURLWithPath: "/tmp/")
    let dataProvider = MockDataProvider()
    let fileManager = FileManager.default

    override func setUpWithError() throws {
        try MockEnvironment.cleanContainerURL()

        super.setUp()
    }

    func copyContainerToTemp(for name: String) throws -> URL {
        guard let containerURL = Bundle(for: Self.self).url(forResource: name, withExtension: "") else {
            throw TestError()
        }

        let destination = URL(fileURLWithPath: "/tmp/\(containerURL.lastPathComponent)")

        try? self.fileManager.removeItem(at: destination)
        try self.fileManager.copyItem(at: containerURL, to: destination)
        return destination
    }

    func testLegacyAnonymousLoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Legacy Anonymous Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .anonymous(let credentials) = roster.active?.state else {
            XCTFail("Migrated conversation is pending.")
            return
        }

        XCTAssertEqual(
            credentials.token,
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MjI4ZjgwMTg5OTE1MTc1OGYwYmNjMDQiLCJhcHBfaWQiOiI1N2QzMzY3NzgyZTNiMmIzZTkwMDAwMDYiLCJpYXQiOjE2NDY4NTIwOTd9.4o5RNgIDs7k3WqVj3dUZtki39ceKt86KcGL8KaBUzYcZS8xwtya9cttQcj0MPDJJFxp_zJQog7vjJyvqcZLDFg"
        )

        XCTAssertEqual(credentials.id, "6228f801899252758f0bcc04")

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let _ = try loader.loadMessages(for: activeRecord)

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
            XCTAssertNotEqual(conversation.interactions.metrics.keys.count, 0)
        }

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testLegacyAnonymousPendingLoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Legacy Anonymous Pending Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .anonymousPending = roster.active?.state else {
            XCTFail("Migrated conversation is not anonymous pending.")
            return
        }

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let _ = try loader.loadMessages(for: activeRecord)

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
        }

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testLegacyLoggedInLoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Legacy Logged In Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .loggedIn(credentials: let credentials, subject: let subject, encryptionKey: let encryptionKey) = roster.active?.state else {
            XCTFail("Migrated conversation is not logged in.")
            return
        }

        XCTAssertEqual(
            credentials.token,
            "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJDbGllbnRUZWFtIiwiZXhwIjoxNjc5Mjc1MDgwLjE0NDU1OCwiaWF0IjoxNjc5MDE1ODgzLjc4MzExMiwic3ViIjoiRnJhbmsifQ.q2gwXhurxO4Kst-D3lMA5qwzVww_TEUIX5oJO_bhhW2KGNnRSPMFfsLGHZHI3OLedVPXvnbdWQAsvtg2_-8Jxw"
        )

        XCTAssertEqual(credentials.id, "6413bfac0f06c21d5f10b9c8")
        XCTAssertEqual(subject, "Frank")
        XCTAssertEqual(encryptionKey, Data(base64Encoded: "DSVDTuA285GBnfWtZXDvhHDxwpQkF1wq9ycl4WX1QQg="))

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let _ = try loader.loadMessages(for: activeRecord)

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
        }

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testLegacyLoggedInAndLoggedOutLoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Legacy Logged In & Logged Out Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            XCTAssertEqual(roster.loggedOut.count, 1)

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .loggedIn(credentials: let credentials, subject: let subject, encryptionKey: let encryptionKey) = roster.active?.state else {
            XCTFail("Migrated conversation is not logged in.")
            return
        }

        XCTAssertEqual(
            credentials.token,
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpYXQiOjE2NzkwMTU5NTAuODQzMjYyLCJzdWIiOiJTa3kiLCJleHAiOjE2NzkyNzUxNDIuODI4OTQzLCJpc3MiOiJDbGllbnRUZWFtIn0.xh93AR5dfIFeuysnt5NMg8g2coVM7HB0S4exDYSCBpbL95-HUch1AoySi9WnR1o3-NaD4rqKnKGsE6nmrPcr5Q"
        )

        XCTAssertEqual(credentials.id, "6413c00fd658d71cde0b1fa2")
        XCTAssertEqual(subject, "Sky")
        XCTAssertEqual(encryptionKey, Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M="))

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let _ = try loader.loadMessages(for: activeRecord)

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
        }

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testLegacyLoggedOutLoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Legacy Logged Out Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            return roster
        }

        XCTAssertNil(roster.active)

        XCTAssertEqual(roster.loggedOut.count, 1)

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testBeta3Loading() throws {
        let containerURL = try self.copyContainerToTemp(for: "Beta3 Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let _ = try loader.loadPayloads()

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .anonymous(let credentials) = roster.active?.state else {
            XCTFail("Migrated conversation is pending.")
            return
        }

        XCTAssertEqual(
            credentials.token,
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MDhiM2I4MTEyNjBmNjZmMmMwZjY5ZDMiLCJhcHBfaWQiOiI1NWYzMWJjZDIyNTcwZWIxNDYwMDAwMzIiLCJpYXQiOjE2MTk3Mzc0NzN9.CR4vqdkXi1FQAHHttM0hRV8XMXjU2h35Ztg9B7y39BGNZK7Z9xx_i-UlX1rmEtbmJ9W03Qs21mloE3DX48ghyf"
        )

        XCTAssertEqual(credentials.id, "818b3b811260f66f2c0f69d3")

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let _ = try loader.loadMessages(for: activeRecord)

            XCTAssertNotEqual(conversation.codePoints.metrics.keys.count, 0)
            XCTAssertNotEqual(conversation.interactions.metrics.keys.count, 0)
        }

        // Should delete the problematic files.
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Conversation.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("PayloadQueue.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("MessageList.plist").path))

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }

    func testALoading() throws {
        let containerURL = try self.copyContainerToTemp(for: "A Data")
        let context = LoaderContext(containerURL: containerURL, cacheURL: self.cacheURL, appCredentials: self.appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let roster = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster(with: MockTokenStore())
            let payloads = try loader.loadPayloads()

            if payloads.count < 13 {
                XCTFail("Expected 13 payloads")
                throw ApptentiveError.internalInconsistency
            }

            XCTAssertEqual(payloads[6].contentType, "application/json;charset=UTF-8")
            XCTAssertTrue(payloads[7].contentType?.hasPrefix("multipart/mixed") ?? false)

            return roster
        }

        guard let activeRecord = roster.active else {
            XCTFail("No active record.")
            return
        }

        guard case .anonymous(let credentials) = roster.active?.state else {
            XCTFail("Migrated conversation is pending.")
            return
        }

        XCTAssertEqual(
            credentials.token,
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJ0eXBlIjoiYW5vbiIsImlzcyI6ImFwcHRlbnRpdmUiLCJzdWIiOiI2MTk1YWM1MzY3NTlhZDU0ODcwMGY1ZjEiLCJhcHBfaWQiOiI1ZjM1NzEyYjRhYmY5OTA0YjYwMDAwMWUiLCJpYXQiOjE2MzcxOTg5MzF9.ZKGv8JC1yK1CSFlovh6Cst1VY75jDw5RjKlxVGUEIaIPxMAgzND8j-yvh6OQU2zXPB2s8LEiosq3JeIDQDCH9f"
        )

        XCTAssertEqual(credentials.id, "3605ac536759ad548700f5f1")

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            let conversation = try loader.loadConversation(for: activeRecord)
            let messages = try loader.loadMessages(for: activeRecord)

            XCTAssertEqual(conversation.person.customData["String"] as? String, "String")
            XCTAssertEqual(messages?.messages.count, 2)
        }

        // Should delete the problematic files.
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("Conversation.A.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("PayloadQueue.A.plist").path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("MessageList.A.plist").path))

        // Shouldn't delete legacy files for now.
        XCTAssertTrue(FileManager.default.fileExists(atPath: containerURL.appendingPathComponent("conversation-v1.meta").path))
    }
}

// TODO: Add test for current data format (once it's established)

struct TestError: Error {}
