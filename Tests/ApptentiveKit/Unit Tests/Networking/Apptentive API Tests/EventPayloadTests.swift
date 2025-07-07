//
//  EventPayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 10/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct EventPayloadTests {
    var event: Event!
    let propertyListEncoder = PropertyListEncoder()
    let propertyListDecoder = PropertyListDecoder()
    let jsonEncoder = JSONEncoder.apptentive
    let jsonDecoder = JSONDecoder.apptentive
    var payloadContext: Payload.Context!

    let encryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
    var encryptedPayloadContext: Payload.Context!

    init() throws {
        self.payloadContext = Payload.Context(tag: ".", credentials: .header(id: "abc", token: "123"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
        self.encryptedPayloadContext = Payload.Context(tag: "abc123", credentials: .embedded(id: "abc"), sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: "123"))

        self.event = Event(name: "Foo bar")
    }

    @Test func testSerialization() throws {
        let testPayload = try Payload(wrapping: self.event, with: self.payloadContext)
        let encodedPayloadData = try self.propertyListEncoder.encode(testPayload)
        let decodedPayload = try self.propertyListDecoder.decode(Payload.self, from: encodedPayloadData)

        #expect(testPayload == decodedPayload)
    }

    @Test func testEncoding() throws {
        let testPayload = try Payload(wrapping: self.event, with: self.payloadContext)

        let expectedEncodedContent = """
            {
                "event": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "label": "local#app#Foo bar"
                }
            }
            """

        try checkPayloadEquivalence(between: testPayload.bodyData!, and: expectedEncodedContent, comparisons: ["label"])
    }

    @Test func testInteractionEventEncoding() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "Survey")

        let event: Event = .launch(from: interaction)
        let interactionPayload = try Payload(wrapping: event, with: self.payloadContext)

        let expectedEncodedContent = """
            {
                "event": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "label": "com.apptentive#Survey#launch",
                    "interaction_id": "\(event.interaction!.id)"
                }
            }
            """

        try checkPayloadEquivalence(between: interactionPayload.bodyData!, and: expectedEncodedContent, comparisons: ["label", "interaction_id"])

        try checkRequestHeading(for: interactionPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "events")
    }

    @Test func testEventUserInfoEncoding() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "NavigateToLink")

        let event: Event = .navigate(to: URL(string: "https://www.apptentive.com")!, success: true, interaction: interaction)
        let interactionPayload = try Payload(wrapping: event, with: self.payloadContext)

        let expectedEncodedContent = """
            {
                "event": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "label": "com.apptentive#NavigateToLink#navigate",
                    "interaction_id": "\(event.interaction!.id)",
                    "data": {
                        "url": "https://www.apptentive.com",
                        "success": true
                    }
                }
            }
            """

        try checkPayloadEquivalence(between: interactionPayload.bodyData!, and: expectedEncodedContent, comparisons: ["label", "interaction_id", "data"])

        try checkRequestHeading(for: interactionPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "events")
    }

    @Test func testCustomDataEventEncoding() throws {
        var event = Event(name: "test")
        event.customData["testCustomData"] = "test"
        let eventPayload = try Payload(wrapping: event, with: self.payloadContext)

        let expectedEncodedContent = """
                        {
                            "event": {
                                "nonce": "abc123",
                                "client_created_at": 1600904569,
                                "client_created_at_utc_offset": 0,
                                "label": "local#app#test",
                                "custom_data": {
                                    "testCustomData": "test"
                               }
                            }
                        }
            """

        try checkPayloadEquivalence(between: eventPayload.bodyData!, and: expectedEncodedContent, comparisons: ["label", "custom_data"])

        try checkRequestHeading(for: eventPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "events")
    }

    @Test func testEncryptedEncoding() throws {
        let encryptedTestPayload = try Payload(wrapping: self.event, with: self.encryptedPayloadContext)

        let expectedEncodedContent = """
            {
                "event": {
                    "nonce": "abc123",
                    "client_created_at": 1600904569,
                    "client_created_at_utc_offset": 0,
                    "label": "local#app#Foo bar"
                }
            }
            """

        try checkEncryptedPayloadEquivalence(between: encryptedTestPayload.bodyData!, and: expectedEncodedContent, comparisons: ["event"], encryptionKey: self.encryptionKey)

        try checkEncryptedRequestHeading(for: encryptedTestPayload, decoder: self.jsonDecoder, expectedMethod: .post, expectedPathSuffix: "events")
    }
}
