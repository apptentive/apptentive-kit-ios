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
struct ComposeTextInputRepresentable: UIViewRepresentable {
    @Binding var text: String
    let minHeight: CGFloat
    let maxHeight: CGFloat

    func makeUIView(context: Context) -> ClampedHeightTextView {
        let textView = ClampedHeightTextView()
        textView.delegate = context.coordinator
        textView.font = Self.cappedFont()
        textView.textColor = .apptentiveMessageCenterTextInput
        textView.backgroundColor = .clear
        if #available(iOS 17.0, *) {
            textView.inlinePredictionType = .no
        }
        textView.adjustsFontForContentSizeCategory = true
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
        uiView.font = Self.cappedFont()
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
        let fitting = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let height = min(max(fitting.height, minHeight), maxHeight)
        return CGSize(width: width, height: height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    /// Caps Dynamic Type scaling for the compose field so accessibility sizes don't
    /// turn the input into a screen-dominating block.
    private static let maxComposeFontPointSize: CGFloat = 22

    /// `UIFont.apptentiveMessageCenterTextInput` is already scaled for the current Dynamic
    /// Type setting (it defaults to `.preferredFont(forTextStyle: .body)`), so clamp its
    /// point size directly instead of running it back through
    /// `UIFontMetrics.scaledFont(for:)` — that call expects an *unscaled* base font and
    /// would double-apply the scaling, making this text visibly larger than UIKit's
    /// `MessageComposeView` (which uses `.apptentiveMessageCenterTextInput` unmodified) at
    /// any non-default text size.
    static func cappedFont() -> UIFont {
        let base = UIFont.apptentiveMessageCenterTextInput
        return base.pointSize > maxComposeFontPointSize ? base.withSize(maxComposeFontPointSize) : base
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

    /// UITextView subclass that clamps its `intrinsicContentSize` height between
    /// `minHeight` and `maxHeight`. Needed for iOS 15, where SwiftUI uses
    /// intrinsic size for sizing UIViewRepresentables.
    final class ClampedHeightTextView: UITextView {
        var minHeight: CGFloat = 0
        var maxHeight: CGFloat = .greatestFiniteMagnitude

        override var intrinsicContentSize: CGSize {
            let referenceWidth = bounds.width > 0 ? bounds.width : UIView.layoutFittingExpandedSize.width
            let fitting = sizeThatFits(CGSize(width: referenceWidth, height: .greatestFiniteMagnitude))
            let height = min(max(fitting.height, minHeight), maxHeight)
            return CGSize(width: UIView.noIntrinsicMetric, height: height)
        }
    }
}
