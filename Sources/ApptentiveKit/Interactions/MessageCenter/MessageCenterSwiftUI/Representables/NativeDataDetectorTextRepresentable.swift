//
//  NativeDataDetectorTextRepresentable.swift
//  ApptentiveKit
//
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Renders text in a non-editable `UITextView` with `dataDetectorTypes = .all`, giving
/// tapped links, phone numbers, addresses, and dates the same native system menu (e.g.
/// "Add to Calendar" for a detected date) that `MessageSentCell`/`MessageReceivedCell`
/// already get in the UIKit Message Center. Only usable from iOS 16 because it relies on
/// `sizeThatFits(_:uiView:context:)` for accurate SwiftUI layout sizing — see
/// `ComposeTextInputRepresentable` for the same technique applied to editable text.
///
/// `isSelectable` is left at its default `true` — despite `MessageSentCell`/
/// `MessageReceivedCell` using the exact same UITextView configuration, tapping a detected
/// date/link here currently selects the word and surfaces the generic text-selection menu
/// (with the data-detector actions buried on a second page) instead of the compact
/// single-tap popup. Setting `isSelectable = false` was tried and made data-detector
/// interaction stop working entirely (Apple's docs confirm `isSelectable` gates link/data
/// -detector interaction too, not just manual selection) — so that's not viable. The
/// remaining discrepancy vs. the UIKit cells is still unexplained and needs more
/// on-device investigation (possibly a SwiftUI `ScrollView` gesture-recognizer conflict).
@available(iOS 16.0, *)
struct NativeDataDetectorText: UIViewRepresentable {
    let text: String
    var textColor: UIColor
    var textAlignment: TextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    /// Clears the system text-selection highlight (rounded highlight + grab handles) that
    /// briefly flashes when tapping a detected date/link. `isSelectable` must stay `true` for
    /// data-detector taps to work at all (see this type's doc comment), which means a tap is
    /// first handled as a word selection before the detector's menu appears. Immediately
    /// clearing the selection here suppresses that visible flash without disabling detection,
    /// since the tap has already been recognized by the time this delegate callback fires.
    final class Coordinator: NSObject, UITextViewDelegate {
        func textViewDidChangeSelection(_ textView: UITextView) {
            if textView.selectedTextRange != nil {
                textView.selectedTextRange = nil
            }
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .all
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.font = .apptentiveMessageLabel
        textView.adjustsFontForContentSizeCategory = true
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if uiView.textColor != textColor {
            uiView.textColor = textColor
        }
        let nsAlignment = textAlignment.nsTextAlignment(layoutDirection: context.environment.layoutDirection)
        if uiView.textAlignment != nsAlignment {
            uiView.textAlignment = nsAlignment
        }
        uiView.invalidateIntrinsicContentSize()
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: fitting.height)
    }
}

extension TextAlignment {
    /// Maps to `NSTextAlignment`, resolving leading/trailing against the interface layout direction.
    ///
    /// `.natural` follows the direction of the text itself (English text in an Arabic interface would
    /// hug the left edge), whereas SwiftUI's `Text` follows the interface direction. Resolving explicitly
    /// keeps the text view consistent with the surrounding `Text` views (sender name, status caption).
    func nsTextAlignment(layoutDirection: LayoutDirection) -> NSTextAlignment {
        let isRTL = layoutDirection == .rightToLeft
        switch self {
        case .leading: return isRTL ? .right : .natural
        case .center: return .center
        case .trailing: return isRTL ? .left : .right
        }
    }
}
