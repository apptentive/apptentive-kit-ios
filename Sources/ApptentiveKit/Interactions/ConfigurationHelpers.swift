//
//  ConfigurationHelpers.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/13/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    func apptentiveDecodeHTML(forKey key: K) throws -> AttributedString {
        let html = try self.decode(String.self, forKey: key)
        return SimpleHTMLParser.parseHTML(html)
    }

    func apptentiveDecodeHTMLIfPresent(forKey key: K) throws -> AttributedString? {
        guard let htmlString = try self.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        return SimpleHTMLParser.parseHTML(htmlString)
    }
}
