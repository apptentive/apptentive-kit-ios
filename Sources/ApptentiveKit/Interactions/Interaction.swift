//
//  Interaction.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

/// An `Interaction` represents an interaction with the user, typically via display of view controller.
struct Interaction: Decodable {
    let id: String
    let configuration: InteractionConfiguration

    /// The raw value of the interaction type.
    let typeName: String

    /// Creates a new interaction from a decoder.
    /// - Parameter decoder: The decoder from which to decode the interaction.
    /// - Throws: Any errors encountered when decoding, such as missing keys or type mismatches.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: InteractionCodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.typeName = try container.decode(String.self, forKey: .type)

        do {
            switch self.typeName {
            case "AppleRatingDialog":
                self.configuration = .appleRatingDialog

            case "EnjoymentDialog":
                self.configuration = .enjoymentDialog(try container.decode(EnjoymentDialogConfiguration.self, forKey: .configuration))

            case "NavigateToLink":
                self.configuration = .navigateToLink(try container.decode(NavigateToLinkConfiguration.self, forKey: .configuration))

            case "Survey":
                self.configuration = .surveyV12(try container.decode(SurveyConfiguration.self, forKey: .configuration))

            case "TextModal":
                self.configuration = .textModal(try container.decode(TextModalConfiguration.self, forKey: .configuration))

            case "MessageCenter":
                self.configuration = .messageCenter(try container.decode(MessageCenterConfiguration.self, forKey: .configuration))

            case "Initiator":
                self.configuration = .initiator

            default:
                let typeName = self.typeName
                Logger.interaction.warning("Interaction of type \(typeName) is not implemented.")
                self.configuration = .notImplemented
            }
        } catch let error {
            let id = self.id
            let typeName = self.typeName
            Logger.interaction.error("Failure decoding configuration for interaction id \(id) of type \(typeName): \(String(describing: error))")

            self.configuration = .failedDecoding
        }
    }

    enum InteractionCodingKeys: String, CodingKey {
        case id
        case type
        case apiVersion = "api_version"
        case configuration
    }

    enum InteractionConfiguration {
        case appleRatingDialog
        case enjoymentDialog(EnjoymentDialogConfiguration)
        case navigateToLink(NavigateToLinkConfiguration)
        case textModal(TextModalConfiguration)
        case messageCenter(MessageCenterConfiguration)
        case surveyV12(SurveyConfiguration)
        case initiator
        case notImplemented
        case failedDecoding
    }

    internal init(id: String, configuration: Interaction.InteractionConfiguration, typeName: String, format: String?) {
        self.id = id
        self.configuration = configuration
        self.typeName = typeName
    }
}
