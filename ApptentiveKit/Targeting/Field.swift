//
//  Field.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Field: ExpressibleByStringLiteral {
    typealias StringLiteralType = String

    let fullPath: String
    let position: Int
    let parentKeys: [String]
    let keys: [String]

    init(stringLiteral: String) {
        self.fullPath = stringLiteral
        self.position = 0

        self.parentKeys = []
        self.keys = stringLiteral.components(separatedBy: "/")
    }

    init(string: String, position: Int? = nil) throws {
        self.fullPath = string
        let position = position ?? 0
        self.position = position
        let components = string.components(separatedBy: "/")

        if position >= components.count {
            throw TargetingError.unexpectedEndOfField(fullPath, position)
        }

        self.parentKeys = components.prefix(position).reversed()
        self.keys = Array(components.suffix(from: position))
    }

    func nextComponent(_ steps: Int? = nil) throws -> Self {
        let steps = steps ?? 1

        return try Self(string: self.fullPath, position: self.position + steps)
    }
}
