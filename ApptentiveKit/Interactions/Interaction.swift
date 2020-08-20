//
//  Interaction.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

/// An `Interaction` represents an interaction with the user, typically via display of view controller.
public struct Interaction: Decodable {
    let id: String
    let configuration: InteractionConfiguration

    /// The raw value of the interaction type.
    public let typeName: String

    /// Creates a new interaction from a decoder.
    /// - Parameter decoder: The decoder from which to decode the interaction.
    /// - Throws: Any errors encountered when decoding, such as missing keys or type mismatches.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: InteractionCodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.typeName = try container.decode(String.self, forKey: .type)

        switch self.typeName {
        case "Survey":
            let configuration = try container.decode(SurveyConfiguration.self, forKey: .configuration)
            self.configuration = InteractionConfiguration.survey(configuration)

        default:
            self.configuration = InteractionConfiguration.notImplemented
        }
    }

    enum InteractionCodingKeys: String, CodingKey {
        case id
        case type
        case configuration
    }

    enum InteractionConfiguration {
        case survey(SurveyConfiguration)
        case notImplemented
    }
}
