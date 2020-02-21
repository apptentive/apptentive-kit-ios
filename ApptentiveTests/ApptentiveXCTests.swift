//
//  ApptentiveXCTests.swift
//  ApptentiveTests
//
//  Created by Apptentive on 2/21/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Foundation
import XCTest
@testable import Apptentive

class AuthenticationFeatureTest: XCTestCase {
    
    struct MockAuthenticator: Authenticating {
        let shouldSucceed: Bool
        
        func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
            completion(self.shouldSucceed)
        }
    }
    
    func testSDKRegistrationSucceedsWithPositiveConfirmation() {
        
        self.sdkRegistrationWithConfirmation(shouldSucceed: true) {
            XCTAssertTrue($0)
        }
    }
    
    func testSDKRegistrationFailsWithNegativeConfirmation() {
        
        self.sdkRegistrationWithConfirmation(shouldSucceed: false) {
            XCTAssertFalse($0)
        }
    }
    
    func sdkRegistrationWithConfirmation(shouldSucceed: Bool, asserts: @escaping (Bool)->()) {

        let authenticator = MockAuthenticator(shouldSucceed: shouldSucceed)
        
        let expectation = XCTestExpectation()
        
        Apptentive(authenticator: authenticator).register(key: "", signature: "") { success in
            asserts(success)
            expectation.fulfill()
        }
    }
}
