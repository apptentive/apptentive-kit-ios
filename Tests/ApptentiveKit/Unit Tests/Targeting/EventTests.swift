//
//  EventTests.swift
//
//
//  Created by Frank Schmitt on 10/24/19.
//

import Testing

@testable import ApptentiveKit

struct EventTests: Sendable {
    @Test func testHostAppEvent() {
        let event1 = Event(name: "launch")

        #expect(event1.codePointName == "local#app#launch")

        let event2 = Event(name: "sales/order#1-100%-{complete}!")

        #expect(event2.codePointName == "local#app#sales%2Forder%231-100%25-{complete}!")
    }

    @Test func testLiteral() {
        let event: Event = "launch"

        #expect(event.codePointName == "local#app#launch")
    }
}
