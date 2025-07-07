//
//  EnjoymentDialogConfiguration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct EnjoymentDialogConfiguration: Decodable, Equatable {
    let title: AttributedString
    let yesText: String
    let noText: String

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.apptentiveDecodeHTML(forKey: .title)
        self.yesText = try container.decode(String.self, forKey: .yesText)
        self.noText = try container.decode(String.self, forKey: .noText)
    }

    enum CodingKeys: String, CodingKey {
        case title
        case yesText = "yes_text"
        case noText = "no_text"
    }
}
