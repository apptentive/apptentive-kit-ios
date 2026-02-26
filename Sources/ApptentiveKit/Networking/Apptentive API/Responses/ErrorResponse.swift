//
//  ErrorResponse.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/24/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable, Sendable {
    let error: String?
    let errorType: AuthenticationFailureReason?

    enum CodingKeys: String, CodingKey {
        case error
        case errorType = "error_type"
    }
}
