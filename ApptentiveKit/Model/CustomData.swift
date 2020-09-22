//
//  CustomData.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

struct CustomData: Equatable, Codable {
    var customData: [String: Codable]

    init() {
        self.customData = [:]
    }

    mutating func merge(with newer: CustomData) {
        self.customData = self.customData.merging(newer.customData) { (old, new) in
            new
        }
    }

    subscript(key: String) -> Codable? {
        get {
            return self.customData[key]
        }
        set {
            self.customData[key] = newValue
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try self.customData.keys.forEach { (key) in
            let codingKey = try CodingKeys.key(for: key)
            let value = self.customData[key]

            switch value {
            case let string as String:
                try container.encode(string, forKey: codingKey)
            case let float as Float:
                try container.encode(float, forKey: codingKey)
            case let int as Int:
                try container.encode(int, forKey: codingKey)
            case let bool as Bool:
                try container.encode(bool, forKey: codingKey)
            default:
                throw ApptentiveError.invalidCustomDataType(value)
            }
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.customData = [:]

        try container.allKeys.forEach { codingKey in
            if let int = try? container.decode(Int.self, forKey: codingKey) {
                customData[codingKey.stringValue] = int
            } else if let float = try? container.decode(Float.self, forKey: codingKey) {
                customData[codingKey.stringValue] = float
            } else if let bool = try? container.decode(Bool.self, forKey: codingKey) {
                customData[codingKey.stringValue] = bool
            } else if let string = try? container.decode(String.self, forKey: codingKey) {
                customData[codingKey.stringValue] = string
            } else {
                throw ApptentiveError.invalidCustomDataType(nil)
            }
        }
    }

    static func == (lhs: CustomData, rhs: CustomData) -> Bool {
        lhs.customData.keys.allSatisfy({ (key) -> Bool in
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
