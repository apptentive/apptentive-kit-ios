//
//  TermsAndConditions.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 4/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents the terms of service to be shown to users at the bottom of surveys.
public class TermsOfService {
    public init(bodyText: String?, linkURL: URL?) {
        self.bodyText = bodyText
        self.linkURL = linkURL
    }
    /// The text to be shown on the terms of service button.
    public var bodyText: String?

    /// The terms of service url to be navigated to (must have https:// prefix).
    public var linkURL: URL?
}
