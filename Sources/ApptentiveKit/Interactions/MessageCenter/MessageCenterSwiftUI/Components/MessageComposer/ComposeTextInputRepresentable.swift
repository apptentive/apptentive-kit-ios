//
//  ComposeTextInputRepresentable.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Editable multi-line text input wrapping `UITextView`. Mirrors the UIKit compose view's
/// behavior: clear background (parent applies fill/glass), Dynamic Type support, and
/// height clamped between `minHeight` and `maxHeight`. Above `maxHeight` the text view
/// becomes scrollable.
///
/// The font is resolved from `dynamicTypeSize` on every update (see `font(for:)`),
/// so changing the text size in Settings while Message Center is open resizes both the
/// text and the field.
struct ComposeTextInputRepresentable: UIViewRepresentable {
    @Binding var text: String
    /// Shown by the parent while `text` is empty. Used only for sizing, so the text view
    /// is as tall as a wrapped placeholder and every placeholder line is tappable.
    let placeholder: String
    let dynamicTypeSize: DynamicTypeSize
    let minHeight: CGFloat
    let maxHeight: CGFloat

    func makeUIView(context: Context) -> ClampedHeightTextView {
        let textView = ClampedHeightTextView()
        textView.placeholder = placeholder
        textView.delegate = context.coordinator
        textView.font = Self.font(for: dynamicTypeSize)
        textView.textColor = .apptentiveMessageCenterTextInput
        textView.backgroundColor = .clear
        if #available(iOS 17.0, *) {
            textView.inlinePredictionType = .no
        }
        // The font is set explicitly in `updateUIView` from the SwiftUI environment.
        textView.adjustsFontForContentSizeCategory = false
        textView.isScrollEnabled = false
        textView.returnKeyType = .default
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.minHeight = minHeight
        textView.maxHeight = maxHeight
        textView.accessibilityIdentifier = "composeTextView"
        return textView
    }

    func updateUIView(_ uiView: ClampedHeightTextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        let font = Self.font(for: dynamicTypeSize)
        if uiView.font != font {
            uiView.font = font
        }
        uiView.placeholder = placeholder
        uiView.minHeight = minHeight
        uiView.maxHeight = maxHeight

        let fittingSize = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: .greatestFiniteMagnitude))
        let shouldScroll = fittingSize.height > maxHeight
        if uiView.isScrollEnabled != shouldScroll {
            uiView.isScrollEnabled = shouldScroll
        }
        uiView.invalidateIntrinsicContentSize()
    }

    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ClampedHeightTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? uiView.bounds.width
        return CGSize(width: width, height: uiView.clampedHeight(forWidth: width))
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    /// The compose font for `dynamicTypeSize`, matching UIKit's `MessageComposeView` (no size cap).
    ///
    /// `UIFont.apptentiveMessageCenterTextInput` is resolved once, at the text size in effect
    /// when it's first accessed, so it's re-resolved here for `dynamicTypeSize`.
    /// It's intentionally not run through `UIFontMetrics.scaledFont(for:)`: that call expects
    /// an *unscaled* base font and would double-apply the scaling.
    static func font(for dynamicTypeSize: DynamicTypeSize) -> UIFont {
        let traitCollection = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        return UIFont.apptentiveMessageCenterTextInput.apptentiveResized(for: traitCollection)
    }

    /// Height of a single line of compose text, used to size the field's minimum height.
    static func lineHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        ceil(font(for: dynamicTypeSize).lineHeight)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            if text.wrappedValue != textView.text {
                text.wrappedValue = textView.text
            }
        }
    }

    /// UITextView subclass that clamps its height between `minHeight` and `maxHeight`.
    /// While empty, it's at least as tall as the wrapped placeholder.
    /// `intrinsicContentSize` is needed for iOS 15, where SwiftUI uses it to size
    /// UIViewRepresentables.
    final class ClampedHeightTextView: UITextView {
        var minHeight: CGFloat = 0
        var maxHeight: CGFloat = .greatestFiniteMagnitude
        var placeholder: String = "" {
            didSet {
                if placeholder != oldValue {
                    invalidateIntrinsicContentSize()
                }
            }
        }

        override var intrinsicContentSize: CGSize {
            let referenceWidth = bounds.width > 0 ? bounds.width : UIView.layoutFittingExpandedSize.width
            return CGSize(width: UIView.noIntrinsicMetric, height: clampedHeight(forWidth: referenceWidth))
        }

        func clampedHeight(forWidth width: CGFloat) -> CGFloat {
            let textHeight = sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
            let height = min(max(textHeight, minHeight), maxHeight)
            // The placeholder isn't capped by `maxHeight`: it can't scroll, so the field
            // grows to show (and accept taps on) every placeholder line.
            if text.isEmpty, !placeholder.isEmpty, let font {
                return max(height, placeholderHeight(forWidth: width, font: font))
            }
            return height
        }

        private func placeholderHeight(forWidth width: CGFloat, font: UIFont) -> CGFloat {
            // Matches the text view's layout: insets and line fragment padding are zero.
            let availableWidth = max(width - textContainerInset.left - textContainerInset.right - 2 * textContainer.lineFragmentPadding, 0)
            let bounds = (placeholder as NSString).boundingRect(
                with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            return ceil(bounds.height) + textContainerInset.top + textContainerInset.bottom
        }
    }
}

extension UIContentSizeCategory {
    /// Maps a SwiftUI `DynamicTypeSize` to the matching UIKit content size category.
    init(_ dynamicTypeSize: DynamicTypeSize) {
        switch dynamicTypeSize {
        case .xSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .xLarge: self = .extraLarge
        case .xxLarge: self = .extraExtraLarge
        case .xxxLarge: self = .extraExtraExtraLarge
        case .accessibility1: self = .accessibilityMedium
        case .accessibility2: self = .accessibilityLarge
        case .accessibility3: self = .accessibilityExtraLarge
        case .accessibility4: self = .accessibilityExtraExtraLarge
        case .accessibility5: self = .accessibilityExtraExtraExtraLarge
        @unknown default: self = .large
        }
    }
}
