//
//  String+HTML.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 4/4/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

public enum HTMLTextAlignment: String {
    case center = "center"
    case left = "left"
    case right = "right"
}

public enum SystemFontNames: String {
    case html = "-apple-system"
    case os = ".SFUI"
}

extension String {
    public func attributedString(withFont font: UIFont, alignment: HTMLTextAlignment) -> NSMutableAttributedString? {
        //If the default font is used we set the font name to `-apple-system` for HTML to read.
        let fontName = font.fontName.contains(SystemFontNames.os.rawValue) ? SystemFontNames.html.rawValue : font.fontName

        let styledHTMLString = "<html style=\"font-family: \(fontName); font-size: \(font.pointSize);text-align: \(alignment.rawValue);\">\(self)</html>"
        if let data = styledHTMLString.data(using: .utf16) {
            do {
                let attributedString = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
                return attributedString
            } catch {
                ApptentiveLogger.default.error("Error creating attributed string from HTML: \(error)")
            }
        } else {
            ApptentiveLogger.default.error("Error converting HTML string to data")
        }
        return nil
    }

    func containsURL() -> Bool {
        let pattern = "(?i)\\b((?:https?|ftp)://\\S+|www\\.\\S+|(?:[A-Za-z0-9-]+\\.)+[A-Za-z]{2,}(?:/\\S*)?|tel:\\S+|mailto:\\S+)"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        return regex?.firstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count)) != nil
    }

    func removingHTMLTags() -> String {
        let pattern = "<[^>]+>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return self
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        let strippedString = regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "")
        return strippedString
    }
}
