//
//  DataDetectorTextView.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Renders text with detected URLs, phone numbers, and email addresses as tappable
/// links. Backed by a native SwiftUI `Text` over an `AttributedString` so wrapping
/// and content-hugging behave correctly on iOS 15 (where `UIViewRepresentable`
/// lacks the `sizeThatFits(_:uiView:context:)` hook and tends to overflow).
struct DataDetectorTextView: View {
    let text: String
    var textColor: UIColor = .label
    var textAlignment: TextAlignment = .leading

    /// Cached so `NSDataDetector` runs once per `text` (via `.task(id: text)`)
    /// instead of on every body render. The initial value is computed eagerly
    /// in `init` so the first frame already shows detected links.
    @State private var attributed: AttributedString

    init(text: String, textColor: UIColor = .label, textAlignment: TextAlignment = .leading) {
        self.text = text
        self.textColor = textColor
        self.textAlignment = textAlignment
        self._attributed = State(initialValue: Self.detect(in: text))
    }

    var body: some View {
        let base = Text(attributed)
            .font(.body)
            .foregroundColor(Color(uiColor: textColor))
            .multilineTextAlignment(textAlignment)
            .fixedSize(horizontal: false, vertical: true)
            .task(id: text) {
                let new = Self.detect(in: text)
                if attributed != new {
                    attributed = new
                }
            }

        if textAlignment == .center {
            base.frame(maxWidth: .infinity)
        } else {
            base
        }
    }

    private static func detect(in text: String) -> AttributedString {
        var attributed = AttributedString(text)
        let types: NSTextCheckingResult.CheckingType = [.link, .phoneNumber]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return attributed
        }
        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = detector.matches(in: text, options: [], range: fullRange)
        for match in matches {
            guard let stringRange = Range(match.range, in: text),
                let attrRange = Range(stringRange, in: attributed)
            else { continue }
            if let url = match.url {
                attributed[attrRange].link = url
            } else if let phone = match.phoneNumber {
                let digits = phone.filter { $0.isNumber || $0 == "+" }
                if let url = URL(string: "tel:\(digits)") {
                    attributed[attrRange].link = url
                }
            }
        }
        return attributed
    }
}
