//
//  ApptentiveFeatureTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ApptentiveFeatureTests: XCTestCase {
    var baseURL: URL?
    var validKey: String?
    var validSignature: String?

    override func setUp() {
        let bundle = Bundle(for: Self.self)
        guard let key = bundle.object(forInfoDictionaryKey: "APPTENTIVE_API_KEY") as? String,
            let signature = bundle.object(forInfoDictionaryKey: "APPTENTIVE_API_SIGNATURE") as? String,
            let urlString = bundle.object(forInfoDictionaryKey: "APPTENTIVE_API_BASE_URL") as? String,
            let url = URL(string: urlString)
        else {
            return
        }

        self.baseURL = url
        self.validKey = key
        self.validSignature = signature

        apptentiveAssertionHandler = { message, file, line in
            print("\(file):\(line): Apptentive critical error: \(message())")
        }
    }

    override func tearDown() {
        Task { @MainActor in
            Apptentive.alreadyInitialized = false
        }
    }

    func testSDKRegistrationSucceedsWithPositiveConfirmation() async throws {
        let credentials = Apptentive.AppCredentials(key: self.validKey!, signature: self.validSignature!)

        try await self.sdkRegistrationWithConfirmation(credentials: credentials)
    }

    func testSDKRegistrationFailsWithNegativeConfirmation() async throws {
        let credentials = Apptentive.AppCredentials(key: "invalid", signature: "invalid")

        do {
            try await self.sdkRegistrationWithConfirmation(credentials: credentials)
            XCTFail("Should not succeed with invalid credentials")
        } catch let error {
            XCTAssertNotNil(error)
        }
    }

    func testSuccessfulSDKRegistration() async {
        let result = await self.sdkRegistrationWithConfirmation()
        XCTAssertTrue(result)
    }

    @MainActor func sdkRegistrationWithConfirmation() async -> Bool {
        let apptentive = Apptentive(containerDirectory: UUID().uuidString, hostContext: HostContext())
        (apptentive.hostContext as! HostContext).protectedDataDidBecomeAvailable(notification: Notification(name: Notification.Name(rawValue: "foo")))
        let credentials = Apptentive.AppCredentials(key: self.validKey!, signature: self.validSignature!)

        do {
            try await apptentive.register(
                with: credentials, region: .us,
                environment: .init({ _, _ in
                    "https://api.apptentive.com"
                }))
            return true
        } catch {
            return false
        }
    }

    @MainActor func sdkRegistrationWithConfirmation(credentials: Apptentive.AppCredentials) async throws {
        let apptentive = Apptentive(containerDirectory: UUID().uuidString, hostContext: HostContext())
        (apptentive.hostContext as! HostContext).protectedDataDidBecomeAvailable(notification: Notification(name: Notification.Name(rawValue: "foo")))

        try await apptentive.register(
            with: credentials, region: .us,
            environment: .init({ _, _ in
                "https://api.apptentive.com"
            }))
    }
}
