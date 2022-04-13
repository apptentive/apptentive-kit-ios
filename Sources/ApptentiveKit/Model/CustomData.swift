//
//  CustomData.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Groups the different data types that we can store/transmit/evaluate in custom data.
public protocol CustomDataCompatible {}

extension String: CustomDataCompatible {}
extension Double: CustomDataCompatible {}
extension Float: CustomDataCompatible {}
extension Int: CustomDataCompatible {}
extension Bool: CustomDataCompatible {}

/// Represents device or person custom data.
public struct CustomData: Equatable, Codable {
    /// The internal representation of the custom data.
    var customData: [String: CustomDataCompatible]

    /// Initializes a new empty custom data object.
    public init() {
        self.customData = [:]
    }

    /// Merges the custom data with newer custom data.
    /// - Parameter newer: The newer custom data to merge in.
    mutating func merge(with newer: CustomData) {
        self.customData = self.customData.merging(newer.customData) { (old, new) in
            new
        }
    }

    /// Accesses the custom data entry with the given key.
    /// - Parameter key: The key corresponding to the custom data entry.
    /// - Returns The value associated with the key.
    public subscript(key: String) -> CustomDataCompatible? {
        get {
            return self.customData[key]
        }
        set {
            self.customData[key] = newValue
        }
    }

    /// Lists the keys for existing custom data items.
    public var keys: Dictionary<String, CustomDataCompatible>.Keys {
        return self.customData.keys
    }

    // swift-format-ignore
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try self.customData.keys.forEach { (key) in
            let codingKey = try CodingKeys.key(for: key)
            let value = self.customData[key]

            switch value {
            case let string as String:
                try container.encode(string, forKey: codingKey)
            case let double as Double:
                try container.encode(double, forKey: codingKey)
            case let int as Int:
                try container.encode(int, forKey: codingKey)
            case let bool as Bool:
                try container.encode(bool, forKey: codingKey)
            default:
                throw ApptentiveError.invalidCustomDataType(value)
            }
        }
    }

    // swift-format-ignore
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customData = [:]

        try container.allKeys.forEach { codingKey in
            if let int = try? container.decode(Int.self, forKey: codingKey) {
                self.customData[codingKey.stringValue] = int
            } else if let double = try? container.decode(Double.self, forKey: codingKey) {
                self.customData[codingKey.stringValue] = double
            } else if let bool = try? container.decode(Bool.self, forKey: codingKey) {
                self.customData[codingKey.stringValue] = bool
            } else if let string = try? container.decode(String.self, forKey: codingKey) {
                self.customData[codingKey.stringValue] = string
            } else {
                throw ApptentiveError.invalidCustomDataType(nil)
            }
        }
    }

    // swift-format-ignore
    public static func == (lhs: CustomData, rhs: CustomData) -> Bool {
        let allKeys = Array(lhs.customData.keys) + Array(rhs.customData.keys)

        return allKeys.allSatisfy({ (key) -> Bool in
            switch (lhs.customData[key], rhs.customData[key]) {
            case let (lhFloat, rhFloat) as (Float, Float):
                return lhFloat == rhFloat

            case let (lhInt, rhInt) as (Int, Int):
                return lhInt == rhInt

            case let (lhBool, rhBool) as (Bool, Bool):
                return lhBool == rhBool

            case let (lhString, rhString) as (String, String):
                return lhString == rhString

            default:
                return false
            }
        })
    }

    struct CodingKeys: CodingKey {
        var stringValue: String

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        var intValue: Int?

        init?(intValue: Int) {
            self.stringValue = String(intValue)
        }

        static func key(for string: String) throws -> Self {
            guard let key = Self(stringValue: string) else {
                throw ApptentiveError.internalInconsistency
            }

            return key
        }
    }
}
