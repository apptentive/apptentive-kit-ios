//
//  HTMLLabel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/24/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import UIKit

class HTMLLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.accessibilityTraits = .staticText
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            updateAttributedText()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var html: String? {
        didSet {
            self.updateAttributedText()
        }
    }

    override var font: UIFont? {
        get {
            super.font
        }
        set {
            super.font = newValue
            self.updateAttributedText()
        }
    }

    var textStyle: UIFont.TextStyle = .body {
        didSet {
            self.updateAttributedText()
        }
    }

    private var isBold: Bool {
        return .headline == self.textStyle
    }

    private var computedFont: UIFont {
        if let font {
            return font
        } else {
            return .preferredFont(forTextStyle: self.textStyle)
        }
    }

    private var isSystemFont: Bool {
        return self.computedFont.fontName.contains(".SFUI")
    }

    private var fontSize: Double {
        if self.isSystemFont {
            return UIFont.preferredFont(forTextStyle: self.textStyle, compatibleWith: self.traitCollection).pointSize
        } else {
            return UIFontMetrics.default.scaledFont(for: self.computedFont, compatibleWith: self.traitCollection).pointSize
        }
    }

    private var htmlAlignment: String {
        switch self.textAlignment {
        case .left:
            return "left"

        case .center:
            return "center"

        case .right:
            return "right"

        case .justified:
            return "justify"

        default:
            return "left"
        }
    }

    private var fontWeight: String {
        return isBold ? "600" : "400"
    }

    private var fontFamily: String {
        if self.computedFont.fontName.contains(".SFUI") {
            return "-apple-system"
        } else {
            return self.computedFont.familyName
        }

    }

    private var styleAttributeValue: String {
        return "font-family: '\(self.fontFamily)'; font-size: \(self.fontSize)px; text-align: \(self.htmlAlignment); font-weight: \(self.fontWeight);"
    }

    private func updateAttributedText() {
        if let html = self.html {
            let previousTextColor = self.textColor

            do {
                let htmlString = "<html style=\"\(self.styleAttributeValue)\"><head><meta charset=\"utf-8\"></head><body>\(self.html ?? "")</body></html>"

                guard let data = htmlString.data(using: .utf8) else {
                    throw ApptentiveError.internalInconsistency
                }

                self.attributedText = try NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil)
            } catch let error {
                ApptentiveLogger.default.error("Unable to parse HTML: \(error.localizedDescription)")
                self.text = html
            }

            self.accessibilityLabel = self.text
            self.textColor = previousTextColor
        }
    }

    private func attributedTextWithLinks() -> NSAttributedString {
        guard let attributedText = attributedText else { return NSAttributedString() }

        let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)

        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: attributedText.string, options: [], range: NSRange(location: 0, length: attributedText.length))

        matches?.forEach { match in
            let linkRange = match.range
            if let matchURL = match.url {
                mutableAttributedText.addAttribute(.link, value: matchURL, range: linkRange)
            }
        }

        return mutableAttributedText
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
}
