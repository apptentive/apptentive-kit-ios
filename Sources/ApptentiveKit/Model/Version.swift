//
//  Version.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/22/19.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Version: Equatable, Comparable, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, CustomDebugStringConvertible, Codable {
    /// The major version of the version object, corresponding to the first integer.

    /// Set to nil if the version is initialized with a non-conforming string.
    let major: Int?

    /// The minor version of the version object, corresponding to the second integer.

    /// Set to 0 if no minor version is specified, or to nil if the version is initialized with a non-conforming string.
    let minor: Int?

    /// The patch version of the version object, corresponding to the second integer.

    /// Set to 0 if no patch version is specified, or to nil if the version is initialized with a non-conforming string.
    let patch: Int?

    /// The string used to initialize the version.
    let versionString: String

    /// Whether the version conforms to semanitc versioning (consists of up to three positive integers separated by periods).
    let isSemantic: Bool

    /// Creates a new version object using the given string.
    /// - Parameter versionString: The string used to create the version.
    init(string versionString: String) {
        let scanner = Scanner(string: versionString)

        var major: Int?
        var minor: Int?
        var patch: Int?

        endOfSemanticVersion: do {
            var integer: Int = 0

            if scanner.scanInt(&integer) {
                major = integer
            }

            if scanner.scanString(".") == nil {
                break endOfSemanticVersion
            }

            if scanner.scanInt(&integer) {
                minor = integer
            }

            if scanner.scanString(".") == nil {
                break endOfSemanticVersion
            }

            if scanner.scanInt(&integer) {
                patch = integer
            }
        }

        if let major = major, scanner.isAtEnd {
            self.init(major: major, minor: minor, patch: patch)
        } else {
            self.init(nonSemanticVersionString: versionString)
        }
    }

    private init(nonSemanticVersionString: String) {
        self.major = nil
        self.minor = nil
        self.patch = nil

        self.versionString = nonSemanticVersionString

        self.isSemantic = false
    }

    init(major: Int, minor: Int? = nil, patch: Int? = nil) {
        self.major = major
        self.minor = minor ?? 0
        self.patch = patch ?? 0

        self.isSemantic = major >= 0 && minor ?? 0 >= 0 && patch ?? 0 >= 0

        var versionString = "\(major)"

        if let minor = minor {
            versionString.append(".\(minor)")
        }

        if let patch = patch {
            versionString.append(".\(patch)")
        }

        self.versionString = versionString
    }

    init(stringLiteral value: String) {
        self.init(string: value)
    }

    init(integerLiteral value: Int) {
        self.init(major: value)
    }

    // MARK: Comparable

    static func < (lhs: Version, rhs: Version) -> Bool {

        guard let lhsMajor = lhs.major, let rhsMajor = rhs.major,
            let lhsMinor = lhs.minor, let rhsMinor = rhs.minor,
            let lhsPatch = lhs.patch, let rhsPatch = rhs.patch
        else {
            return lhs.versionString < rhs.versionString
        }

        if lhsMajor == rhsMajor {
            if lhsMinor == rhsMinor {
                return lhsPatch < rhsPatch
            } else {
                return lhsMinor < rhsMinor
            }
        } else {
            return lhsMajor < rhsMajor
        }
    }

    // MARK: Equatable

    static func == (lhs: Version, rhs: Version) -> Bool {
        if lhs.isSemantic && rhs.isSemantic {
            return lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.patch == rhs.patch
        } else {
            return lhs.versionString == rhs.versionString
        }
    }

    // MARK: Custom Debug String Convertible

    var debugDescription: String {
        return "Version(\(versionString))"
    }
}
