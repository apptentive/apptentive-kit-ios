//
//  AuthenticationFeatureTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class AuthenticationFeatureTests: XCTestCase {
    var authenticationUrl = URL(string: "http://localhost:8080/conversations")!

    override func setUp() {
        #if Dev
            self.authenticationUrl = URL(string: "https://bdd-api-default.k8s.dev.apptentive.com/conversations")!
        #elseif Stage
            self.authenticationUrl = URL(string: "https://bdd-api-default.k8s.shared-dev.apptentive.com/conversations")!
        #elseif Prod
            self.authenticationUrl = URL(string: "https://bdd-api-default.k8s.production.apptentive.com/conversations")!
        #endif
    }

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

    func sdkRegistrationWithConfirmation(credentials: Apptentive.Credentials, asserts: @escaping (Bool) -> Void) {
        let authenticator = ApptentiveAuthenticator(url: self.authenticationUrl, requestor: URLSession.shared)

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
