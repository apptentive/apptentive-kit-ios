//
//  EngagementManifestShimTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 12/1/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class EngagementManifestShimTests: XCTestCase {
    var inputManifest: EngagementManifest? = nil

    override func setUpWithError() throws {
        guard let url = Bundle(for: type(of: self)).url(forResource: "testManifest1", withExtension: "json", subdirectory: "Test Manifests") else {
            throw TargeterTestError.manifestNotFound
        }

        let data = try Data(contentsOf: url)

        self.inputManifest = try JSONDecoder().decode(EngagementManifest.self, from: data)
    }

    func testTransform() throws {
        guard let inputManifest = self.inputManifest else {
            return XCTFail("Didn't load test manifest")
        }

        let inputInteractionIndex = Dictionary(uniqueKeysWithValues: inputManifest.interactions.map { ($0.id, $0) })

        guard let inputInteraction = inputInteractionIndex["55e6037a45ce55118900001a"],
            case let Interaction.InteractionConfiguration.textModal(inputConfiguration) = inputInteraction.configuration
        else {
            return XCTFail("Didn't find TextModal configuration for interaction with ID 55e6037a45ce55118900001a in input")
        }

        let outputManifest = transformEngagementManifest(inputManifest)
        let outputInteractionIndex = Dictionary(uniqueKeysWithValues: outputManifest.interactions.map { ($0.id, $0) })

        guard let outputInteraction = outputInteractionIndex["55e6037a45ce55118900001a"],
            case let Interaction.InteractionConfiguration.textModal(outputConfiguration) = outputInteraction.configuration
        else {
            return XCTFail("Didn't find TextModal configuration for interaction with ID 55e6037a45ce55118900001a in output")
        }

        // Action events
        XCTAssertEqual(outputConfiguration.actions[0].event, "button_55e6037a45ce551189000016")
        XCTAssertEqual(outputConfiguration.actions[1].event, "button_55e6037a45ce551189000017")
        XCTAssertEqual(outputConfiguration.actions[2].event, "button_55e6037a45ce551189000018")
        XCTAssertNil(outputConfiguration.actions[3].event)  // Invocation-less button shouldn't have event

        // Additional targets
        XCTAssertNotNil(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000016"])
        XCTAssertEqual(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000016"]?[0].interactionID, inputConfiguration.actions[0].invocations?[0].interactionID)

        XCTAssertNotNil(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000017"])
        XCTAssertEqual(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000017"]?[0].interactionID, inputConfiguration.actions[1].invocations?[0].interactionID)

        XCTAssertNotNil(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000018"])
        XCTAssertEqual(outputManifest.targets["com.apptentive#TextModal#button_55e6037a45ce551189000018"]?[0].interactionID, inputConfiguration.actions[2].invocations?[0].interactionID)

        // No invocations for the dismiss button
    }
}
