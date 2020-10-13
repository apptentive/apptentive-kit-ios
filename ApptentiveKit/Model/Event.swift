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
    let name: String
    let vendor: String
    let interaction: String
    // TODO: Add custom data and stuff

    /// Creates an event with the provided name.
    /// - Parameter name: The name of the event.
    public init(name: String) {
        self.name = name
        self.vendor = "local"
        self.interaction = "app"
    }

    init(internalName: String) {
        self.name = internalName
        self.vendor = "com.apptentive"
        self.interaction = "app"
    }

    /// Creates an event with the provided string literal as the name.
    /// - Parameter value: The name of the event.
    public init(stringLiteral value: String) {
        self.init(name: value)
    }

    static var launch = Self(internalName: "launch")
    static var exit = Self(internalName: "exit")
    static var screenshot = Self(internalName: "screenshot")

    var codePointName: String {
        [vendor, interaction, name].map(escape).joined(separator: "#")
    }

    private static let allowedCharacters = CharacterSet(charactersIn: "#%/").inverted

    private func escape(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: Self.allowedCharacters) ?? ""
    }
}
