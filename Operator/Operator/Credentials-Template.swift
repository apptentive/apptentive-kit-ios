//
//  Credentials.swift
//  Operator
//
//  Created by Frank Schmitt on 1/23/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit

// To use the Operator app to test your Alchemer Digital Dashboard settings,
// copy the API key and signature (and optionally your JWT signing secret)
// and enter them below for the `active` static instance of the Operator
// app's Credentials object.
//
// Then rename this file to `Credentials.swift`, open the Operator project,
// and build and run.

extension Credentials {
    static let active: Self = Self(appCredentials: .init(key: "<#Your Alchemer Digital App Key#>",
                                                       signature: "<#Your Alchemer Digital App Signature#>"),
                                 jwtSigningSecret: nil,
                                 region: .us,
                                 environment: .production)
}

