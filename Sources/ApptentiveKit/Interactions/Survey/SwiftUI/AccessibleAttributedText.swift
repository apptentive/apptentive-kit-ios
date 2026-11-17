//
//  AccessibleAttributedText.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/14/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// A view that displays attributed text with keyboard-accessible links and proper line wrapping.
struct AccessibleAttributedText: View {
    @Environment(\.sizeCategory) private var sizeCategory

    let attributedString: AttributedString
    let uiFont: UIFont?
    let textStyle: UIFont.TextStyle
    let foregroundColor: Color?
    let textAlignment: NSTextAlignment
    var isHeader: Bool

    init(_ attributedString: AttributedString, uiFont: UIFont? = nil, textStyle: UIFont.TextStyle = .body, foregroundColor: Color? = nil, textAlignment: NSTextAlignment = .natural, isHeader: Bool = false) {
        self.attributedString = attributedString
        self.uiFont = uiFont
        self.textStyle = textStyle
        self.foregroundColor = foregroundColor
        self.textAlignment = textAlignment
        self.isHeader = isHeader
    }

    var body: some View {
        AttributedTextView(
            attributedString: attributedString,
            uiFont: uiFont,
            textStyle: textStyle,
            foregroundColor: foregroundColor,
            textAlignment: textAlignment,
            isHeader: isHeader,
            sizeCategory: sizeCategory
        )
    }
}

/// A UIViewRepresentable wrapper around a custom label with keyboard-accessible links.
private struct AttributedTextView: UIViewRepresentable {
    let attributedString: AttributedString
    let uiFont: UIFont?
    let textStyle: UIFont.TextStyle
    let foregroundColor: Color?
    let textAlignment: NSTextAlignment
    let isHeader: Bool
    let sizeCategory: ContentSizeCategory

    func makeUIView(context: Context) -> LinkAccessibleLabel {
        let label = LinkAccessibleLabel()
        label.backgroundColor = .clear
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping

        // Force layout priority to ensure proper wrapping
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)

        return label
    }

    /// Without this hook, `LinkAccessibleLabel.intrinsicContentSize` has to fall back to its own
    /// `bounds.width`, which is still zero on the label's first layout pass (a freshly created label,
    /// as happens on every List rebuild since `SurveyView` resets `.id()` on each page transition).
    /// That first pass then reports a wrong (too-short) height for the header, so a `List` section
    /// header showing a long message — e.g. a lengthy Thank You message — can end up overlapping the
    /// content below it until a second layout pass corrects it, which a List's self-sizing header
    /// doesn't reliably trigger on its own. Giving SwiftUI the proposed width up front avoids the
    /// zero-width first pass entirely. iOS 15 still relies on the `bounds.width`/`layoutSubviews`
    /// fallback below, matching `NativeDataDetectorText` in the Message Center, which has the same gap.
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView label: LinkAccessibleLabel, context: Context) -> CGSize? {
        let width = proposal.width ?? label.bounds.width
        let fitting = label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: fitting.height)
    }

    func updateUIView(_ label: LinkAccessibleLabel, context: Context) {
        label.isHeader = isHeader
        var styledString = attributedString

        // preferredFont gives the current Dynamic Type point size; uiFont provides the custom family descriptor.
        let sizedFont = UIFont.preferredFont(forTextStyle: textStyle)
        let baseDescriptor = uiFont.flatMap { f in f.fontName.contains(".SFUI") ? nil : f.fontDescriptor } ?? sizedFont.fontDescriptor

        let runs = Array(styledString.runs)
        for run in runs {
            var traits: UIFontDescriptor.SymbolicTraits = []

            // Bold/italic baked directly into a `.font` attribute (how `SimpleHTMLParser` encodes
            // `<b>`/`<i>` tags — it doesn't set `inlinePresentationIntent`), matching how
            // `RichTextLabel` reads the same runs for Dialog/Message Center rich text.
            if let existingFont = run.uiKit.font {
                if existingFont.fontDescriptor.symbolicTraits.contains(.traitBold) { traits.insert(.traitBold) }
                if existingFont.fontDescriptor.symbolicTraits.contains(.traitItalic) { traits.insert(.traitItalic) }
            }

            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true { traits.insert(.traitBold) }
            if run.inlinePresentationIntent?.contains(.emphasized) == true { traits.insert(.traitItalic) }

            let descriptor = traits.isEmpty ? baseDescriptor : (baseDescriptor.withSymbolicTraits(traits) ?? baseDescriptor)
            styledString[run.range].uiKit.font = UIFont(descriptor: descriptor, size: sizedFont.pointSize)
        }

        if let foregroundColor = foregroundColor {
            styledString.uiKit.foregroundColor = UIColor(foregroundColor)
        }

        let nsAttributedString =
            (try? NSAttributedString(styledString, including: \.uiKit))
            ?? NSAttributedString(string: String(styledString.characters))

        let mutableString = NSMutableAttributedString(attributedString: nsAttributedString)
        addDataDetectedLinks(to: mutableString)
        applyTextAlignment(to: mutableString)

        label.textAlignment = textAlignment
        label.attributedText = mutableString
        label.updateAccessibilityElements()
    }

    /// Paragraph styles embedded in the string (e.g. for HTML lists) override the label's own
    /// `textAlignment`, so update their alignment too while keeping their other properties
    /// (such as list indents), the same way `RichTextLabel` does.
    private func applyTextAlignment(to string: NSMutableAttributedString) {
        guard textAlignment != .natural else { return }

        string.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: string.length)) { value, range, _ in
            guard let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle else { return }
            paragraphStyle.alignment = textAlignment
            string.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        }
    }

    private func addDataDetectedLinks(to string: NSMutableAttributedString) {
        let types: NSTextCheckingTypes =
            NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        guard let detector = try? NSDataDetector(types: types) else { return }

        let plainText = string.string
        let fullRange = NSRange(plainText.startIndex..., in: plainText)

        detector.enumerateMatches(in: plainText, options: [], range: fullRange) { result, _, _ in
            guard let result = result else { return }

            // Don't overwrite explicit links already in the attributed string
            var hasExistingLink = false
            string.enumerateAttribute(.link, in: result.range) { value, _, stop in
                if value != nil {
                    hasExistingLink = true
                    stop.pointee = true
                }
            }
            guard !hasExistingLink else { return }

            let url: URL?
            switch result.resultType {
            case .link:
                url = result.url
            case .phoneNumber:
                url = result.phoneNumber.flatMap { URL(string: "tel:\($0)") }
            default:
                url = nil
            }

            if let url = url {
                string.addAttribute(.link, value: url, range: result.range)
            }
        }
    }
}

/// A UILabel subclass that creates custom accessibility elements for links, making them keyboard-focusable.
private class LinkAccessibleLabel: UILabel {
    var isHeader: Bool = false
    private var linkRanges: [(range: NSRange, url: URL, rect: CGRect)] = []
    private var tapGesture: UITapGestureRecognizer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        self.tapGesture = tap
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard attributedText != nil else { return }

        let location = gesture.location(in: self)

        // Check if tap is on a link
        for (_, url, rect) in linkRanges {
            if rect.contains(location) {
                UIApplication.shared.open(url)
                return
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = sizeThatFits(CGSize(width: bounds.width, height: .greatestFiniteMagnitude))
        return CGSize(width: UIView.noIntrinsicMetric, height: size.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
        updateAccessibilityElements()
    }

    func updateAccessibilityElements() {
        guard let attributedText = attributedText else {
            isAccessibilityElement = true
            accessibilityElements = nil
            return
        }

        linkRanges = []
        var accessibilityElements: [UIAccessibilityElement] = []

        // Find all links in the attributed string
        attributedText.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedText.length)) { value, range, _ in
            if let url = value as? URL {
                // Get the bounding rect for this link
                if let rect = boundingRect(for: range) {
                    linkRanges.append((range, url, rect))

                    // Create an accessibility element for this link
                    let element = UIAccessibilityElement(accessibilityContainer: self)
                    element.accessibilityFrameInContainerSpace = rect
                    element.accessibilityLabel = (attributedText.string as NSString).substring(with: range)
                    element.accessibilityTraits = .link
                    element.accessibilityHint = "Double tap to open link"

                    // Store the URL in the element so we can access it later
                    element.accessibilityValue = url.absoluteString

                    accessibilityElements.append(element)
                }
            }
        }

        if accessibilityElements.isEmpty {
            isAccessibilityElement = true
            self.accessibilityElements = nil
            accessibilityTraits = isHeader ? [.staticText, .header] : .staticText
        } else {
            isAccessibilityElement = false
            self.accessibilityElements = accessibilityElements
        }
    }

    private func boundingRect(for range: NSRange) -> CGRect? {
        guard let attributedText = attributedText else { return nil }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: bounds.size)
        let textStorage = NSTextStorage(attributedString: attributedText)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        // Adjust for label alignment
        rect.origin.x += textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).origin.x
        rect.origin.y += textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).origin.y

        return rect
    }

    override func accessibilityActivate() -> Bool {
        // Find which accessibility element is focused and open its URL
        if let focusedElement = UIAccessibility.focusedElement(using: nil) as? UIAccessibilityElement,
            let urlString = focusedElement.accessibilityValue,
            let url = URL(string: urlString)
        {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
}
