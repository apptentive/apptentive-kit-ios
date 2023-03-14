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
    }

    override func tearDown() {
        Apptentive.alreadyInitialized = false
    }

    func testSDKRegistrationSucceedsWithPositiveConfirmation() {
        let credentials = Apptentive.AppCredentials(key: self.validKey!, signature: self.validSignature!)

        self.sdkRegistrationWithConfirmation(credentials: credentials) {
            XCTAssertTrue($0)
        }
    }

    func testSDKRegistrationFailsWithNegativeConfirmation() {
        let credentials = Apptentive.AppCredentials(key: "invalid", signature: "invalid")

        self.sdkRegistrationWithConfirmation(credentials: credentials) {
            XCTAssertFalse($0)
        }
    }

    @available(iOS 13.0.0, *)
    func testSuccessfulSDKRegistration() async {
        let result = await self.sdkRegistrationWithConfirmation()
        XCTAssertTrue(result)
    }

    @available(iOS 13.0.0, *)
    func sdkRegistrationWithConfirmation() async -> Bool {
        let apptentive = Apptentive(baseURL: baseURL, containerDirectory: UUID().uuidString, backendQueue: nil, environment: Environment())
        (apptentive.environment as! Environment).protectedDataDidBecomeAvailable(notification: Notification(name: Notification.Name(rawValue: "foo")))
        let credentials = Apptentive.AppCredentials(key: self.validKey!, signature: self.validSignature!)

        do {
         try await apptentive.register(with: credentials)
           return true
        } catch {
            return false
        }
    }

    func sdkRegistrationWithConfirmation(credentials: Apptentive.AppCredentials, asserts: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Authentication request complete")

        guard let baseURL = self.baseURL else {
            return XCTFail("Base URL is invalid")
        }

        let apptentive = Apptentive(baseURL: baseURL, containerDirectory: UUID().uuidString, backendQueue: nil, environment: Environment())
        (apptentive.environment as! Environment).protectedDataDidBecomeAvailable(notification: Notification(name: Notification.Name(rawValue: "foo")))

        apptentive.register(with: credentials) { result in
            switch result {
            case .success:
                asserts(true)
            case .failure(_):
                asserts(false)
            }

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 1) { error in
            if let error = error {
                XCTFail("Authentication request timed out: \(error.localizedDescription)")
            }
        }
    }
}
