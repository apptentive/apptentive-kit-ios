//
//  EventTests.swift
//
//
//  Created by Frank Schmitt on 10/24/19.
//

import XCTest

@testable import ApptentiveKit

class EventTests: XCTestCase {
    func testHostAppEvent() {
        let event1 = Event(name: "launch")

        XCTAssertEqual(event1.codePointName, "local#app#launch")

        let event2 = Event(name: "sales/order#1-100%-{complete}!")

        XCTAssertEqual(event2.codePointName, "local#app#sales%2Forder%231-100%25-{complete}!")
    }

    func testLiteral() {
        let event: Event = "launch"

        XCTAssertEqual(event.codePointName, "local#app#launch")
    }

    static var allTests = [
        ("testHostAppEvent", testHostAppEvent),
        ("testLiteral", testLiteral),
    ]
}
