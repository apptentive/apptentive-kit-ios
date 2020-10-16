//
//  Event.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/24/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes an event that represents a view or action in your app that you would like to track to help trigger interactions.
///
/// Use the `Apptentive` object's `engage(event:from:)` method to record events in your app.
public struct Event: ExpressibleByStringLiteral, Codable {

    /// The name of the event as provided by the customer.
    let name: String

    /// The source of the event, basically whether it comes from the host app or is internal.
    let vendor: String

    /// The interaction, if any, that the event was engaged by (this will be `app` if there is no interaction).
    let interaction: String

    /// Creates an event with the provided name.
    /// - Parameter name: The name of the event.
    public init(name: String) {
        self.name = name
        self.vendor = "local"
        self.interaction = "app"
    }

    /// Creates an event with the provided string literal as the name.
    /// - Parameter value: The name of the event.
    public init(stringLiteral value: String) {
        self.init(name: value)
    }

    /// Returns a `#`-separated string incorporating the vendor, interaction and name, all appropriately percent-escaped.
    ///
    /// Code points are used when looking up potential invocations in the engagement manifest's `targets` section.
    var codePointName: String {
        [vendor, interaction, name].map(escape).joined(separator: "#")
    }

    private static let allowedCharacters = CharacterSet(charactersIn: "#%/").inverted

    /// Escapes an event name to comply with the requirements for code points.
    ///
    /// Characters in the set `#`, `%`, and `/` need to be percent-escaped.
    /// - Parameter string: the string to escape.
    /// - Returns: The escaped string.
    private func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: Self.allowedCharacters) ?? ""
    }
}
