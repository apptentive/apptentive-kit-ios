//
//  QuestionResponse.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

enum QuestionResponse: Equatable {
    case empty
    case skipped
    case answered([Answer])
}
