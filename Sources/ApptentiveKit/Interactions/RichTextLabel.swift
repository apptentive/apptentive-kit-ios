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

    private func updateAttributedText() {
        if let attributedString = self.attributedString {
            let previousTextColor = self.textColor
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

            self.attributedText = nsAttributedString

            self.accessibilityLabel = self.text
            self.textColor = previousTextColor

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
        guard let attributedText = attributedText else { return .zero }
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize(width: frame.width, height: CGFloat.greatestFiniteMagnitude))

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = attributedText else { return }
        let tapLocation = gesture.location(in: self)

        attributedText.enumerateAttributes(in: NSRange(location: 0, length: attributedText.length), options: []) { attributes, range, _ in
            if let link = attributes[.link] as? URL {
                let boundingRect = self.boundingRect(forCharacterRange: range)
                if boundingRect.contains(tapLocation) {
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
