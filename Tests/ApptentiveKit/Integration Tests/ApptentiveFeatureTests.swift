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
        if let defaultDefaultsURL = Bundle(for: type(of: self)).url(forResource: "Defaults", withExtension: "plist"), let defaultDefaults = NSDictionary(contentsOf: defaultDefaultsURL) as? [String: AnyObject] {
            UserDefaults.standard.register(defaults: defaultDefaults)
        }

        guard let key = UserDefaults.standard.string(forKey: "Key"), let signature = UserDefaults.standard.string(forKey: "Signature"), let urlString = UserDefaults.standard.string(forKey: "ServerURL"), let url = URL(string: urlString) else {
            return XCTFail("Unable to read URL/credentials from Defaults.plist")
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

    func sdkRegistrationWithConfirmation(credentials: Apptentive.AppCredentials, asserts: @escaping (Bool) -> Void) {
        let expectation = self.expectation(description: "Authentication request complete")

        guard let baseURL = self.baseURL else {
            return XCTFail("Base URL is invalid")
        }

        Apptentive(baseURL: baseURL).register(credentials: credentials) { result in
            switch result {
            case .success(true):
                asserts(true)
            case .success(false):
                asserts(false)
            case .failure(_):
                asserts(false)
            }

            // asserts(success)

            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 5.0) { error in
            if let error = error {
                XCTFail("Authentication request timed out: \(error.localizedDescription)")
            }
        }
    }
}
