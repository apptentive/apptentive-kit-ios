//
//  ConversationTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct ConversationTests {
    @Test func testMerge() throws {
        let dataProvider = MockDataProvider()

        let conversation1 = Conversation(dataProvider: dataProvider)
        var conversation2 = Conversation(dataProvider: dataProvider)

        conversation2.person.name = "Testy McTesterson"
        conversation2.appRelease.version = "2"

        #expect(conversation1.person.name != conversation2.person.name)
        #expect(conversation1.appRelease.version != conversation2.appRelease.version)

        let merged = try conversation1.merged(with: conversation2)

        #expect(merged.person.name == conversation2.person.name)
        #expect(merged.appRelease.version == conversation2.appRelease.version)

        #expect(merged.appRelease.isUpdatedVersion)
    }

    @Test func testCoding() throws {
        let dataProvider = MockDataProvider()

        var conversation = Conversation(dataProvider: dataProvider)

        conversation.interactions.record(
            .answered([
                .choice("id1"),
                .other("id2", "value2"),
                .freeform("value3"),
                .range(5),
            ]),
            for: "abcwer")

        let _ = try? conversation.value(for: "random/xyz/percent")

        let encoder = PropertyListEncoder()

        let data = try encoder.encode(conversation)

        let decoder = PropertyListDecoder()

        let conversation2 = try decoder.decode(Conversation.self, from: data)

        #expect(conversation == conversation2)
    }
}
