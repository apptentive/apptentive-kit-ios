//
//  PersonTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Testing

@testable import ApptentiveKit

struct PersonTests {
    @Test func testCustomData() {
        var person = Person()

        person.customData["string"] = "string"
        person.customData["number"] = 5
        person.customData["float"] = 1.1
        person.customData["boolean"] = true

        #expect(person.customData["string"] as? String == "string")
        #expect(person.customData["number"] as? Int == 5)
        #expect(person.customData["float"] as? Double == 1.1)
        #expect(person.customData["boolean"] as? Bool == true)
    }

    @Test func testMerge() {
        var person1 = Person()
        person1.name = "Test"
        person1.emailAddress = "noreply@apptentive.com"

        var person2 = Person()
        person2.name = "Testy"

        person1.customData["foo"] = "bar"
        person2.customData["foo"] = "baz"
        person2.customData["bar"] = "foo"

        person1.merge(with: person2)

        #expect(person1.name == "Testy")
        #expect(person1.emailAddress == "noreply@apptentive.com")
        #expect(person1.customData["foo"] as? String == "baz")
        #expect(person1.customData["bar"] as? String == "foo")
    }

    @Test func testContentDiff() {
        var person1 = Person()
        person1.name = "Test"
        person1.emailAddress = "noreply@apptentive.com"
        person1.customData["string"] = "foo"

        var person2 = Person()
        person2.name = "Best"
        person2.emailAddress = "noreply@apptentive.com"
        person2.customData["string"] = "bar"

        #expect(!PersonContent(with: person1).differs(from: PersonContent(with: person1)))
        #expect(PersonContent(with: person1).differs(from: PersonContent(with: person2)))

        person2.name = "Test"

        #expect(!PersonContent(with: person1).differs(from: PersonContent(with: person2), includeCustomData: false))
        #expect(PersonContent(with: person1).differs(from: PersonContent(with: person2), includeCustomData: true))
    }
}
