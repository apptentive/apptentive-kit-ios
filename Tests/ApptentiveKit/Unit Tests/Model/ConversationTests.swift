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

    @Test func testMergePreservesLastSyncedProperties() throws {
        let dataProvider = MockDataProvider()

        // `conversation1` represents the disk-loaded conversation, with a real sync baseline.
        var conversation1 = Conversation(dataProvider: dataProvider)
        conversation1.lastSyncedPerson = conversation1.person
        conversation1.lastSyncedDevice = conversation1.device
        conversation1.lastSyncedAppRelease = conversation1.appRelease

        // `conversation2` represents the in-memory placeholder conversation, which never has a sync baseline.
        let conversation2 = Conversation(dataProvider: dataProvider)

        #expect(conversation2.lastSyncedPerson == nil)

        let merged = try conversation1.merged(with: conversation2)

        #expect(merged.lastSyncedPerson == conversation1.lastSyncedPerson)
        #expect(merged.lastSyncedDevice == conversation1.lastSyncedDevice)
        #expect(merged.lastSyncedAppRelease == conversation1.lastSyncedAppRelease)
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

    @Test func testDecodingConversationWithoutLastSyncedProperties() throws {
        // Simulates a Conversation.plist persisted by an SDK version that predates the
        // `lastSyncedAppRelease`/`lastSyncedPerson`/`lastSyncedDevice` properties.
        let dataProvider = MockDataProvider()
        let conversation = Conversation(dataProvider: dataProvider)

        let data = try PropertyListEncoder().encode(conversation)

        var plistObject = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]
        plistObject.removeValue(forKey: "lastSyncedAppRelease")
        plistObject.removeValue(forKey: "lastSyncedPerson")
        plistObject.removeValue(forKey: "lastSyncedDevice")

        let legacyData = try PropertyListSerialization.data(fromPropertyList: plistObject, format: .xml, options: 0)

        let decoded = try PropertyListDecoder().decode(Conversation.self, from: legacyData)

        #expect(decoded.lastSyncedAppRelease == nil)
        #expect(decoded.lastSyncedPerson == nil)
        #expect(decoded.lastSyncedDevice == nil)
    }
}
