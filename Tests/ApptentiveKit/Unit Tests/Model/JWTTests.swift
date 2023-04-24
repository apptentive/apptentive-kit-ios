//
//  JWTTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/16/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class JWTTests: XCTestCase {
    static let secret = "I'm actually a dog".data(using: .utf8)

    func testNoSignatureCheck() throws {
        let jwt = try JWT(string: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c")

        XCTAssertEqual(jwt.header.type, .jwt)
        XCTAssertEqual(jwt.header.algorithm, .hmacSHA256)

        XCTAssertEqual(jwt.payload.issuedAt, Date(timeIntervalSince1970: 1_516_239_022))
        XCTAssertEqual(jwt.payload["name"] as? String, "John Doe")
    }

    func testAllClaimTypes() throws {
        let jwt = try JWT(string: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwic3RyaW5nIjoiU3RyaW5nIiwiaWF0IjoxNTE2MjM5MDIyLCJpbnQiOjEyMywiZG91YmxlIjozLjE0MTYsImJvb2wiOnRydWV9.EXJjf1Ey6W5KVKcgOwlPxgeumyZ8ds0cnrRoFxfqIH0")

        XCTAssertEqual(jwt.payload["string"] as? String, "String")
        XCTAssertEqual(jwt.payload["int"] as? Int, 123)
        XCTAssertEqual(jwt.payload["double"] as! Double, 3.1416, accuracy: 0.0001)
        XCTAssertEqual(jwt.payload["bool"] as? Bool, true)

        // Omit standard claims from subscripting
        XCTAssertNil(jwt.payload["iat"])
    }
}
