//
//  RichTextLabel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/24/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

class RichTextLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.accessibilityTraits = .staticText
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var attributedString: AttributedString? {
        didSet {
            self.updateAttributedText()
        }
    }

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

    private var computedFont: UIFont {
        if let font, !font.fontName.contains(".SFUI") {
            // Font has been explicitly set to something that's not the system font.
            return font
        } else {
            return .preferredFont(forTextStyle: self.textStyle)
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

            nsAttributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
                var newFontDescriptor: UIFontDescriptor = self.computedFont.fontDescriptor

                if let oldFont = value as? UIFont {
                    var traits: UIFontDescriptor.SymbolicTraits = []
                    let descriptor = oldFont.fontDescriptor

                    if descriptor.symbolicTraits.contains(.traitBold) || self.textStyle == .headline {
                        traits.insert(.traitBold)
                    }

                    if descriptor.symbolicTraits.contains(.traitItalic) {
                        traits.insert(.traitItalic)
                    }

                    if let updatedDescriptor = newFontDescriptor.withSymbolicTraits(traits) {
                        newFontDescriptor = updatedDescriptor
                    }
                }

                let newFont = UIFont(descriptor: newFontDescriptor, size: self.computedFont.pointSize)

                let scaledFont = UIFontMetrics(forTextStyle: self.textStyle).scaledFont(for: newFont)
                nsAttributedString.addAttribute(.font, value: scaledFont, range: range)
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
            self.addCustomAccessibilityActions()

            if self.accessibilityCustomActions?.count ?? 0 > 0 {
                self.isUserInteractionEnabled = true
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                addGestureRecognizer(tapGesture)
            }
        }
    }

    private func addCustomAccessibilityActions() {
        var customActions: [UIAccessibilityCustomAction] = []

        attributedText?.enumerateAttribute(.link, in: NSRange(location: 0, length: attributedText?.length ?? 0), options: []) { (value, range, _) in
            if let link = value as? URL {

                let actionFormat = NSLocalizedString("OpenLinkAction", bundle: .apptentive, value: "Open %@ link", comment: "Action name format for opening a link")
                let actionName = String(format: actionFormat, link.absoluteString)
                let customAction = UIAccessibilityCustomAction(name: actionName, target: self, selector: #selector(handleLink(_:)))
                customActions.append(customAction)
            }
        }

        accessibilityCustomActions = customActions.isEmpty ? nil : customActions
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
        guard let attributedText = attributedText else { return }
        let tapLocation = gesture.location(in: self)

        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { attributes, range, _ in
            if let link = attributes[.link] as? URL {
                let boundingRect = self.boundingRect(forCharacterRange: range)
                if boundingRect.contains(tapLocation) {
                    // TODO: Use Interaction Delegate to open links (PBI-8569)
                    UIApplication.shared.open(link)
                }
            }
        }
    }

    @objc private func handleLink(_ action: UIAccessibilityCustomAction) -> Bool {

        if let urlString = action.name.components(separatedBy: " ").last,
            let url = URL(string: urlString)
        {
            UIApplication.shared.open(url)
            return true
        }
        return false
    }
}
