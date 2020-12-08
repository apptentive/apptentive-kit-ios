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
        case "EnjoymentDialog":
            self.configuration = .enjoymentDialog(try container.decode(EnjoymentDialogConfiguration.self, forKey: .configuration))

        case "NavigateToLink":
            self.configuration = .navigateToLink(try container.decode(NavigateToLinkConfiguration.self, forKey: .configuration))

        case "Survey":
            self.configuration = .survey(try container.decode(SurveyConfiguration.self, forKey: .configuration))

        case "TextModal":
            self.configuration = .textModal(try container.decode(TextModalConfiguration.self, forKey: .configuration))

        default:
            self.configuration = .notImplemented
        }

    }

    /// Initializes an interaction with the given parameters.
    ///
    /// This can be removed once the API sends us pre-transformed engagement manifests.
    /// We need to be able to create new TextModal interactions to make the transform work.
    /// - Parameters:
    ///   - id: The interaction ID.
    ///   - typeName: The type of interaction as a string.
    ///   - configuration: The configuration as an enum value.
    init(id: String, typeName: String, configuration: InteractionConfiguration) {
        self.id = id
        self.typeName = typeName
        self.configuration = configuration
    }

    enum InteractionCodingKeys: String, CodingKey {
        case id
        case type
        case configuration
    }

    enum InteractionConfiguration {
        case enjoymentDialog(EnjoymentDialogConfiguration)
        case navigateToLink(NavigateToLinkConfiguration)
        case survey(SurveyConfiguration)
        case textModal(TextModalConfiguration)
        case notImplemented
    }
}
