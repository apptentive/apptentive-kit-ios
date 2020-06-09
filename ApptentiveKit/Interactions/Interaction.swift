//
//  Interaction.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Foundation
import UIKit

public struct Interaction: Decodable, Identifiable {
    public let id: String
    let type: InteractionType
    let configuration: SurveyConfiguration

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: InteractionCodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(InteractionType.self, forKey: .type)
        self.configuration = try container.decode(SurveyConfiguration.self, forKey: .configuration)
    }

    enum InteractionCodingKeys: String, CodingKey {
        case id
        case type
        case configuration
    }
}

enum InteractionType: String, Decodable {
    case survey = "Survey"
}
