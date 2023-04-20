//
//  InteractionTestHelpers.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/1/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

class InteractionTestHelpers {  // Has to be a class so that Bundle(for:) works.
    static func loadInteraction(named name: String) throws -> Interaction {
        guard let url = Bundle(for: self).url(forResource: name, withExtension: "json", subdirectory: "Test Interactions") else {
            throw InteractionTestHelpersError.interactionDataNotFound
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder.apptentive.decode(Interaction.self, from: data)
    }

    enum InteractionTestHelpersError: Error {
        case interactionDataNotFound
    }
}
