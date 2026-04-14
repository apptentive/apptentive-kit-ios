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
    let position: DialogViewModel.Position?
    let verticalMargins: CGFloat?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.title = try container.apptentiveDecodeHTML(forKey: .title)
        self.yesText = try container.decode(String.self, forKey: .yesText)
        self.noText = try container.decode(String.self, forKey: .noText)
        self.position = try container.decodeIfPresent(DialogViewModel.Position.self, forKey: .position)
        self.verticalMargins = try container.decodeIfPresent(CGFloat.self, forKey: .verticalMargins)
    }

    enum CodingKeys: String, CodingKey {
        case title
        case yesText = "yes_text"
        case noText = "no_text"
        case position
        case verticalMargins = "vertical_margins"
    }
}
