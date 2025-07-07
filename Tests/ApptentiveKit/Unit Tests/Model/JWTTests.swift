//
//  JWTTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/16/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct JWTTests {

    @Test func testNoSignatureCheck() throws {
        let jwt = try JWT(string: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c")

        #expect(jwt.header.type == .jwt)
        #expect(jwt.header.algorithm == .hmacSHA256)

        #expect(jwt.payload.issuedAt == Date(timeIntervalSince1970: 1_516_239_022))
        #expect(jwt.payload["name"] as? String == "John Doe")
    }

    @Test func testAllClaimTypes() throws {
        let jwt = try JWT(string: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic3RyaW5nIjoiU3RyaW5nIiwiaWF0IjoxNTE2MjM5MDIyLCJpbnQiOjEyMywiZG91YmxlIjozLjE0MTYsImJvb2wiOnRydWV9.EXJjf1Ey6W5KVKcgOwlPxgeumyZ8ds0cnrRoFxfqIH0")

        #expect(jwt.payload["string"] as? String == "String")
        #expect(jwt.payload["int"] as? Int == 123)
        #expect(jwt.payload["double"] as! Double == 3.1416)
        #expect(jwt.payload["bool"] as? Bool == true)

        // Omit standard claims from subscripting
        #expect(jwt.payload["iat"] == nil)
    }
}
