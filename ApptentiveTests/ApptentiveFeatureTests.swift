//
//  ApptentiveFeatureTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import XCTest
@testable import Apptentive


class AuthenticationFeatureTests: XCTestCase {

    func testSDKRegistrationSucceedsWithPositiveConfirmation() {
        let credentials = Apptentive.Credentials(key: "valid", signature: "valid")

        self.sdkRegistrationWithConfirmation(credentials: credentials) {
            XCTAssertTrue($0)
        }
    }

    func testSDKRegistrationFailsWithNegativeConfirmation() {
        let credentials = Apptentive.Credentials(key: "", signature: "")

        self.sdkRegistrationWithConfirmation(credentials: credentials) {
            XCTAssertFalse($0)
        }
    }

    func sdkRegistrationWithConfirmation(credentials: Apptentive.Credentials, asserts: @escaping (Bool)->()) {
        let url = URL(string: "https://bdd-api-default.k8s.dev.apptentive.com/conversations")!
        let authenticator = ApptentiveAuthenticator(url: url, requestor: URLSession.shared)

        let expectation = self.expectation(description: "Authentication request complete")

        Apptentive(authenticator: authenticator).register(credentials: credentials) { success in
            asserts(success)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 2.0) { error in
            if let error = error {
                XCTFail("Authentication request timed out: \(error.localizedDescription)")
            }
        }
    }
}
