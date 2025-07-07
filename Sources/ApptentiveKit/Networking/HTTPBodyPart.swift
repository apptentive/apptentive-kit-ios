//
//  HTTPBodyPart.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias MediaType = String

protocol HTTPBodyPart: Sendable {
    var contentType: String { get }
    var contentDisposition: String { get }
    var filename: String? { get }
    var parameterName: String? { get }

    func content(using encoder: JSONEncoder) throws -> Data
}

extension HTTPBodyPart {
    var contentDisposition: String {
        ["form-data", "name=\"\(self.parameterName ?? "data")\"", self.filename.flatMap { "filename=\"\($0)\"" }]
            .compactMap { $0 }
            .joined(separator: "; ")
    }
}
