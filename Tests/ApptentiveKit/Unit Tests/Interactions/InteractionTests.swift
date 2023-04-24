//
//  InteractionTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class InteractionTests: XCTestCase {
    func testInteractionDecoding() throws {
        guard let directoryURL = Bundle(for: type(of: self)).url(forResource: "Test Interactions", withExtension: nil) else {
            return XCTFail("Unable to find test data")
        }

        let localFileManager = FileManager()

        let resourceKeys = Set<URLResourceKey>([.nameKey])
        let directoryEnumerator = localFileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys))!

        for case let fileURL as URL in directoryEnumerator {
            if !fileURL.absoluteString.contains("MessageList.json") {
                let data = try Data(contentsOf: fileURL)

                let _ = try JSONDecoder.apptentive.decode(Interaction.self, from: data)
            }
        }
    }

    func testPlaceholder() {
        let placeholder = EngagementManifest.placeholder

        XCTAssertEqual(placeholder.interactions[0].id, "message_center_fallback")
        XCTAssertEqual(placeholder.targets["com.apptentive#app#show_message_center_fallback"]?[0].interactionID, "message_center_fallback")
    }

    func testApptentiveTheme() {
        Apptentive.shared.applyApptentiveTheme() // Just make sure it doesn't crash
    }
}
