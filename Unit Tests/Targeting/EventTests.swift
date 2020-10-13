//
//  EventTests.swift
//
//
//  Created by Frank Schmitt on 10/24/19.
//

import XCTest
@testable import ApptentiveKit

class EventTests: XCTestCase {
    func testApptentiveEvent() {
        let event1 = Event(internalName: "launch")

        XCTAssertEqual(event1.codePointName, "com.apptentive#app#launch")

        let event2 = Event(internalName: "sales/order#1-100%-{complete}!")

        XCTAssertEqual(event2.codePointName, "com.apptentive#app#sales%2Forder%231-100%25-{complete}!")
    }

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
        ("testApptentiveEvent", testApptentiveEvent),
        ("testHostAppEvent", testHostAppEvent),
        ("testLiteral", testLiteral)
    ]
}
