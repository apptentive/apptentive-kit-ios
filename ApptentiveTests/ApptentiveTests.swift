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

// Test types:
// Feature (live/mock)
// Integrations (live/mock)
// Unit
// Acceptance (Live/End-to-end, live or fake server, actual http requests)

// test principles:
// unit tests test one thing in isolation (no dependecies if possible)
// integration tests test (multiple asseertions, single input - single output, end-to-end)
// test should not need tests too (has behavior, mutable state, imperative logic)

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
                    
                    waitUntil { done in
                        Apptentive(authenticator: authenticator).register(key: "", signature: "") { success in
                            expect(success).to(beTrue())
                            done()
                        }
                    }
                }
            }
            
            context("when an app dev unsuccessfully registers with some key / signature") {
                it("AppDev gets negative confirmation") {
                    let authenticator = MockAuthenticator(shouldSucceed: false)
                    
                    waitUntil { done in
                        Apptentive(authenticator: authenticator).register(key: "", signature: "") { success in
                            expect(success).to(beFalse())
                            done()
                        }
                    }
                }
            }
        }
    }
}

class AuthenticatorIntegrationSpec: QuickSpec {
    override func spec() {
        describe("Authenticator request roundtrip") {
            it("Builds and sends an authentication request, then maps response to a result") {
                
                let requestor = SpyRequestor()
                let authenticator = ApptentiveAuthenticator(requestor: requestor)
                
                waitUntil { done in
                    authenticator.authenticate(key: "", signature: "") { (success) in
                        
                        expect(requestor.request).toNot(beNil()) // asserts build and send
                        expect(success).to(beAKindOf(Bool.self)) // asserts recieve and map
                        
                        done()
                    }
                }
            }
        }
        
        class SpyRequestor: HTTPRequesting {
            var request: URLRequest?
            
            func sendRequest(_ request: URLRequest, completion: @escaping (URLResult) -> ()) {
                self.request = request
                
                let stubReponse = HTTPURLResponse()
                completion((nil, stubReponse, nil))
            }
        }
    }
}

class AuthenticatorSpec: QuickSpec {
    override func spec() {
        describe("Authenticator") {
            it("builds a request for authentication") {
                
                let expectedURL = URL(string: "https://example.com")!
                
                var expectedRequest = URLRequest(url: expectedURL)
                expectedRequest.httpMethod = "some method"
                expectedRequest.addValue("some-head-key", forHTTPHeaderField: "some-header-value")
                
                let request = ApptentiveAuthenticator.buildRequest(key: "", signature: "", url: expectedURL)
                
                expect(request.url).toNot(beNil())
                expect(request.allHTTPHeaderFields).toNot(beEmpty())
                expect(request.httpMethod).toNot(beEmpty())
            }
            
            context("given a successful status code") {
                it("maps a 201 status to success") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)
                    
                    let result = ApptentiveAuthenticator.processResponse(response: response)
                    
                    expect(result).to(beTrue())
                }
            }
            
            context("given a failure") {
                it("maps a 401 status to failure") {
                    let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)
                    
                    let result = ApptentiveAuthenticator.processResponse(response: response)
                    
                    expect(result).to(beFalse())
                }
                
                it("maps no response to failure") {
                    let response: URLResponse? = nil
                    
                    let result = ApptentiveAuthenticator.processResponse(response: response)
                    
                    expect(result).to(beFalse())
                }
            }
        }
        
        struct DummyRequestor: HTTPRequesting {
            func sendRequest(_ request: URLRequest, completion: @escaping (URLResult) -> ()) {}
        }
    }
}

