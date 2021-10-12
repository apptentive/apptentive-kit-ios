//
//  PersonTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class PersonTests: XCTestCase {
    func testCustomData() {
        var person = Person()

        person.customData["string"] = "string"
        person.customData["number"] = 5
        person.customData["boolean"] = true

        XCTAssertEqual(person.customData["string"] as? String, "string")
        XCTAssertEqual(person.customData["number"] as? Int, 5)
        XCTAssertEqual(person.customData["boolean"] as? Bool, true)
    }

    func testMerge() {
        var person1 = Person()
        person1.name = "Test"
        person1.emailAddress = "noreply@apptentive.com"

        var person2 = Person()
        person2.name = "Testy"

        person1.customData["foo"] = "bar"
        person2.customData["foo"] = "baz"
        person2.customData["bar"] = "foo"

        person1.merge(with: person2)

        XCTAssertEqual(person1.name, "Testy")
        XCTAssertEqual(person1.emailAddress, "noreply@apptentive.com")
        XCTAssertEqual(person1.customData["foo"] as? String, "baz")
        XCTAssertEqual(person1.customData["bar"] as? String, "foo")
    }
}
