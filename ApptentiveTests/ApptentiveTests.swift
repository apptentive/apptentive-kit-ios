//
//  ApptentiveTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Nimble
import Quick
@testable import Apptentive

// Test driven approaches:
// TDD (start with test, implement)
// BDD (start with a behavior/feature, write test, implement)

// BDD benefits:
// know where to begin implemnentation (where user starts)
// write least amount of code to get the test to pass (no over-engineered, speculative, unneeded code)
// stay user-focused

// Three test types:
// Feature (live/mock)
// Integrations (live/mock)
// Unit

// test principles:
// unit tests test one thing in isolation (no dependecies if possible)
// integration tests test (multiple asseertions, single input - single output, end-to-end)
// test should not need tests too (has behavior, mutable state, imperative logic)

// Notes:
// input is SDK use developer, customer use app triggers SDK use, API reponse
// output -> API call, interaction, callback by SDK

// JSON file -> test
// SDK call authenticate -> what does it send? correct? test SDK as wrapper on API
// from apddev perspective, not care what API does, where you draw the line

// end-to-end: one end is what customers call (methods), other end server outside SDK/what server sees
// mock/live testing
// abstract low level details for tests

// could pass in wrong key to authenticator, instead of setup (feels like you are fixing the game, rather than mock react)

// pass KS -> SERVER (decides)
// response <- SERVER

// KS -> request with headers
// <- response with status code

// keys URL request, values URL responses (stateless, readable, maintainable)

// test feature behavior as expected by user

/**

- Dummy objects are passed around but never actually used. Usually they are just used to fill parameter lists.
- Fake objects actually have working implementations, but usually take some shortcut which makes them not suitable for production (an in memory database is a good example).
- Stubs provide canned answers to calls made during the test, usually not responding at all to anything outside what's programmed in for the test.
- Spies are stubs that also record some information based on how they were called. One form of this might be an email service that records how many messages it was sent.
- Mocks are what we are talking about here: objects pre-programmed with expectations which form a specification of the calls they are expected to receive.

*/


class AuthenticationFeatureSpec: QuickSpec {
    
    struct MockAuthenticator: Authenticating {
        let shouldSucceed: Bool
        
        func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
            completion(self.shouldSucceed)
        }
    }
    
    override func spec() {
        describe("SDK Authentication") {
            context("when an app dev registers with some key / signature") {
                it("AppDev gets positive confirmation") {
                    let authenticator = MockAuthenticator(shouldSucceed: true)
                    
                    Apptentive(authenticator: authenticator).register(key: "abc", signature: "123") { success in
                        expect(success).to(beTrue())
                    }
                }
            }
            
            context("when an app dev unsuccessfully registers with some key / signature") {
                it("AppDev gets negative confirmation") {
                    let authenticator = MockAuthenticator(shouldSucceed: false)
                    
                    Apptentive(authenticator: authenticator).register(key: "abc", signature: "123") { success in
                        expect(success).to(beFalse())
                    }
                }
            }
        }
    }
}
