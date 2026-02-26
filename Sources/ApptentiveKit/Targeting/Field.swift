//
//  Field.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents a /-delimited array of substrings along with an index into the array.
struct Field: ExpressibleByStringLiteral, Equatable {

    /// The full field name.
    let fullPath: String

    /// The index of the subfield represented by this object.
    let position: Int

    /// The subfields that precede the subfield represented by this object.
    let parentKeys: [String]

    /// The current subfield along with all subsequent ones.
    let keys: [String]

    /// Creates a new field object.
    /// - Parameter stringLiteral: The string representing the field.
    init(stringLiteral: String) {
        self.fullPath = stringLiteral
        self.position = 0

        self.parentKeys = []
        self.keys = stringLiteral.components(separatedBy: "/")
    }

    /// Creates a new field object pointing to a particular subfield.
    /// - Parameters:
    ///   - string: The full field path.
    ///   - position: The position of the subfield that the object should represent.
    /// - Throws: An error if the position is larger than the number of subfields.
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

    /// Returns a field whose position is advanced by the specified amount.
    /// - Parameter steps: The number of steps to advance, which effectively defaults to 1.
    /// - Throws: An error if there aren't enough subfields.
    /// - Returns: A copy of this object whose position is advanced by `steps`.
    func nextComponent(_ steps: Int? = nil) throws -> Self {
        let steps = steps ?? 1

        return try Self(string: self.fullPath, position: self.position + steps)
    }
}
