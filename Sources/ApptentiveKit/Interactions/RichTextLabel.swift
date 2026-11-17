//
//  RichTextLabel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/24/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

@MainActor
protocol RichTextLabelDelegate: AnyObject {
    func handleLink(_ url: URL)
}

class RichTextLabel: UILabel {
    private var linkRanges: [(range: NSRange, url: URL, rect: CGRect)] = []

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.adjustsFontForContentSizeCategory = true
        self.accessibilityTraits = .staticText
        self.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var attributedString: AttributedString? {
        didSet {
            self.updateAttributedText()
        }
    }

    weak var delegate: RichTextLabelDelegate?

    override var font: UIFont? {
        didSet {
            self.updateAttributedText()
        }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            self.updateAttributedText()
        }
    }

    var textStyle: UIFont.TextStyle = .body {
        didSet {
            self.updateAttributedText()
        }
    }

    private var labelTextColor: UIColor?

    override var textColor: UIColor? {
        get {
            return labelTextColor
        }
        set {
            labelTextColor = newValue
            self.updateAttributedText()
        }
    }

    private func updateAttributedText() {
        if let attributedString = self.attributedString {
            let nsAttributedString = NSMutableAttributedString(attributedString)

            // Use preferred font for text style so we scale once and respect Dynamic Type without double-scaling.
            let baseFont = UIFont.preferredFont(forTextStyle: self.textStyle)
            // Custom font: use its descriptor so the family applies; system: use preferred font descriptor.
            let baseDescriptor = (self.font.flatMap { font in font.fontName.contains(".SFUI") ? nil : font.fontDescriptor }) ?? baseFont.fontDescriptor

            var charOffset = 0
            for run in attributedString.runs {
                let runStr = String(attributedString.characters[run.range])
                let nsLen = (runStr as NSString).length
                guard nsLen > 0 else { continue }
                let nsRange = NSRange(location: charOffset, length: nsLen)
                charOffset += nsLen

                var traits: UIFontDescriptor.SymbolicTraits = []

                // Bold/italic from explicit UIFont attribute (backward compat with any non-parser sources)
                if let oldFont = run.uiKit.font {
                    if oldFont.fontDescriptor.symbolicTraits.contains(.traitBold) { traits.insert(.traitBold) }
                    if oldFont.fontDescriptor.symbolicTraits.contains(.traitItalic) { traits.insert(.traitItalic) }
                }

                // Bold/italic from inlinePresentationIntent (set by SimpleHTMLParser)
                if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true { traits.insert(.traitBold) }
                if run.inlinePresentationIntent?.contains(.emphasized) == true { traits.insert(.traitItalic) }

                if self.textStyle == .headline { traits.insert(.traitBold) }

                var newFontDescriptor = baseDescriptor
                if !traits.isEmpty, let updatedDescriptor = baseDescriptor.withSymbolicTraits(traits) {
                    newFontDescriptor = updatedDescriptor
                }

                // Always use preferred font's point size so we scale once (theme fonts are already scaled; avoid double-scaling).
                let fontToApply = UIFont(descriptor: newFontDescriptor, size: baseFont.pointSize)
                nsAttributedString.addAttribute(.font, value: fontToApply, range: nsRange)
            }

            nsAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
                if let paragraphStyle = value as? NSParagraphStyle {
                    guard let mutableParagraphStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle else {
                        return
                    }

                    mutableParagraphStyle.alignment = self.textAlignment

                    nsAttributedString.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: range)
                }
            }

            nsAttributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { (value, range, _) in
                if let _ = value as? URL {
                    self.tintColor.flatMap { nsAttributedString.addAttribute(.foregroundColor, value: $0, range: range) }
                } else {
                    nsAttributedString.addAttribute(.foregroundColor, value: self.labelTextColor ?? .apptentiveLabel, range: range)
                }
            }

            self.attributedText = nsAttributedString
            self.accessibilityLabel = self.text

            self.detectLinks()

            // Add tap gesture if we have links
            if gestureRecognizers?.isEmpty ?? true {
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                addGestureRecognizer(tapGesture)
            }

            // Update accessibility elements for keyboard navigation
            updateAccessibilityElements()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateAttributedText()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateAccessibilityElements()
    }

    private func updateAccessibilityElements() {
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
                let rect = boundingRect(forCharacterRange: range)
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

        if accessibilityElements.isEmpty {
            // No links - treat the whole label as accessible
            isAccessibilityElement = true
            self.accessibilityElements = nil
        } else {
            // Has links - use custom accessibility elements
            isAccessibilityElement = false
            self.accessibilityElements = accessibilityElements
        }
    }

    //    private func addDebugRectangles() {
    //        attributedText?.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedText?.length ?? 0), options: []) { (value, range, _) in
    //            if let _ = value as? URL {
    //                let rect = self.boundingRect(forCharacterRange: range)
    //                let view = UIView(frame: rect)
    //                view.backgroundColor = UIColor.red.withAlphaComponent(0.25)
    //                view.isUserInteractionEnabled = false
    //                self.addSubview(view)
    //            }
    //        }
    //    }
    //
    //    override func layoutSubviews() {
    //        super.layoutSubviews()
    //
    //        if self.frame.width > 0 {
    //            self.addDebugRectangles()
    //        }
    //    }

    private func detectLinks() {
        guard let attributedText = self.attributedText else {
            return
        }

        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            let matches = detector.matches(in: attributedText.string, options: [], range: NSRange(location: 0, length: attributedText.length))

            for match in matches {
                let linkRange = match.range
                if let matchURL = match.url {
                    mutableAttributedText.addAttribute(.link, value: matchURL, range: linkRange)
                }
            }

            self.attributedText = mutableAttributedText
        } catch let error {
            Logger.default.error("Error creating data detector: \(error)")
        }
    }

    private func boundingRect(forCharacterRange range: NSRange) -> CGRect {
        guard let attributedText = self.attributedText else {
            return .zero
        }

        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude))

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = self.numberOfLines
        textContainer.lineBreakMode = self.lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        var boundingRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)

        var lineRect = CGRect.zero
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
            if NSLocationInRange(glyphRange.location, glyphRange) || NSLocationInRange(NSMaxRange(glyphRange) - 1, glyphRange) {
                lineRect = usedRect
                stop.pointee = true
            }
        }

        var offset = frame.width - lineRect.width

        switch (self.textAlignment, self.traitCollection.layoutDirection) {
        case (.left, _), (.justified, _), (.natural, .leftToRight):
            offset = 0
        case (.center, _):
            offset /= 2
        default:
            break
        }

        boundingRect.origin.x += offset

        return boundingRect
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let tapLocation = gesture.location(in: self)

        // Check if tap is on a link using cached linkRanges
        for (_, url, rect) in linkRanges {
            if rect.contains(tapLocation) {
                delegate?.handleLink(url)
                return
            }
        }
    }

    override func accessibilityActivate() -> Bool {
        // Find which accessibility element is focused and open its URL
        if let focusedElement = UIAccessibility.focusedElement(using: nil) as? UIAccessibilityElement,
            let urlString = focusedElement.accessibilityValue,
            let url = URL(string: urlString)
        {
            delegate?.handleLink(url)
            return true
        }
        return false
    }
}
