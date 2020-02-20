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

class Authentication: QuickSpec {
    override func spec() {
        describe("SDK Authentication") {
            context("when an app dev registers with a valid key / signature") {
                it("AppDev gets positive confirmation") {
                    let authenticator = MockAuthenticator(shouldSucceed: true)
                    
                    Apptentive(authenticator: authenticator).register(key: "abc", signature: "123") { success in
                        expect(success).to(beTrue())
                    }
                }
            }
            
            context("when an app dev unsuccessfully registers with a valid key / signature") {
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

struct MockAuthenticator: Authenticating {
    let shouldSucceed: Bool
    
    func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
        completion(shouldSucceed)
    }
}

class ApptentiveAuthenticatorTests: QuickSpec {
    override func spec() {
        
        it("builds a request") {
            let authenticator = ApptentiveAuthenticator(requestor: MockRequestor())
            
            let request = authenticator.buildRequest(key: "abc", signature: "123")

            expect(request.url).to(equal(URL(string: "https://api.apptentive.com/conversations")))
            expect(request.allHTTPHeaderFields?["APPTENTIVE-KEY"]).to(equal("abc"))
            expect(request.allHTTPHeaderFields?["APPTENTIVE-SIGNATURE"]).to(equal("123"))
            expect(request.httpMethod).to(equal("POST"))
        }
        
 /*(       it("sends a request") {
            
            let mockRequestor = MockRequestor()
            let authenticator = ApptentiveAuthenticator(requestor: mockRequestor)
            
            let expectedRequest = URLRequest(url: URL(string: "http://example.com")!)
            authenticator.send(request) { _ in
                expect(mockRequestor.request).to(not(beNil()))
            }
            
            expect(authenticator.send).to.have.been.calledWith(expectedRequest)
        }*/
    }
}

class ApptentiveAuthenticatorIntegrationTests: QuickSpec {
    override func spec() {

        it("authfdjsklfds") {
            let mockRequestor = MockRequestor()
            let authenticator = ApptentiveAuthenticator(requestor: mockRequestor)

            
            authenticator.authenticate(key: "abc", signature: "123", completion: { (success) in
                expect(mockRequestor.request?.url).to(equal(URL(string: "https://api.apptentive.com/conversations")))
                expect(mockRequestor.request?.allHTTPHeaderFields?["APPTENTIVE-KEY"]).to(equal("abc"))
                expect(mockRequestor.request?.allHTTPHeaderFields?["APPTENTIVE-SIGNATURE"]).to(equal("123"))
                expect(mockRequestor.request?.httpMethod).to(equal("POST"))
                
                expect(success).to(beTrue())
            })
        }
    }
}

class MockRequestor: HTTPRequesting {
    var request: URLRequest?

    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        self.request = request
        completion(nil, nil, nil)
    }
}
