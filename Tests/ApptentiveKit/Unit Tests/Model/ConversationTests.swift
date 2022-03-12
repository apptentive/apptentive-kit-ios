//
//  ConversationTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ConversationTests: XCTestCase {

    func testMerge() throws {
        let environment = MockEnvironment()

        let conversation1 = Conversation(environment: environment)
        var conversation2 = Conversation(environment: environment)

        conversation2.person.name = "Testy McTesterson"
        conversation2.appRelease.version = "2"

        XCTAssertNotEqual(conversation1.person.name, conversation2.person.name)
        XCTAssertNotEqual(conversation1.appRelease.version, conversation2.appRelease.version)

        let merged = try conversation1.merged(with: conversation2)

        XCTAssertEqual(merged.person.name, conversation2.person.name)
        XCTAssertEqual(merged.appRelease.version, conversation2.appRelease.version)

        XCTAssertTrue(merged.appRelease.isUpdatedVersion)
    }

    func testCoding() throws {
        let environment = MockEnvironment()

        var conversation = Conversation(environment: environment)

        conversation.interactions.record(
            [
                .choice("id1"),
                .other("id2", "value2"),
                .freeform("value3"),
                .range(5),
            ],
            for: "abcwer")

        let _ = try? conversation.value(for: "random/xyz/percent")

        let encoder = PropertyListEncoder()

        let data = try encoder.encode(conversation)

        let decoder = PropertyListDecoder()

        let conversation2 = try decoder.decode(Conversation.self, from: data)

        XCTAssertEqual(conversation, conversation2)
    }
}
