//
//  EnjoymentDialogConfiguration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/25/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct EnjoymentDialogConfiguration: Decodable {
    let title: String
    let yesText: String
    let noText: String

    enum CodingKeys: String, CodingKey {
        case title
        case yesText = "yes_text"
        case noText = "no_text"
    }
}
