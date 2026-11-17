//
//  DataDetectorTextView.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Renders message text with detected links/phone numbers/dates as tappable.
/// On iOS 16+, delegates to `NativeDataDetectorText`, a `UIViewRepresentable`-wrapped
/// `UITextView` with `dataDetectorTypes = .all` — this gets the same native system menu
/// (e.g. "Add to Calendar" for a detected date) that the UIKit Message Center already has,
/// for free. Below iOS 16, falls back to `LegacyDataDetectorText`, a native SwiftUI `Text`
/// over an `AttributedString` that only detects links/phone numbers (no dates), because
/// `UIViewRepresentable` lacks the `sizeThatFits(_:uiView:context:)` hook pre-iOS 16 and
/// tends to overflow when wrapping `UITextView`.
struct DataDetectorTextView: View {
    let text: String
    var textColor: UIColor = .label
    var textAlignment: TextAlignment = .leading

    var body: some View {
        centered(
            Group {
                if #available(iOS 16.0, *) {
                    NativeDataDetectorText(text: text, textColor: textColor, textAlignment: textAlignment)
                } else {
                    LegacyDataDetectorText(text: text, textColor: textColor, textAlignment: textAlignment)
                }
            }
        )
    }

    @ViewBuilder
    private func centered<V: View>(_ view: V) -> some View {
        if textAlignment == .center {
            view.frame(maxWidth: .infinity)
        } else {
            view
        }
    }
}

/// Text-only fallback for iOS 15: renders via SwiftUI `Text(AttributedString)` and only
/// detects links/phone numbers (no dates — see `DataDetectorTextView`'s doc comment).
private struct LegacyDataDetectorText: View {
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
        Text(attributed)
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
