import UIKit

extension UILabel {
    func enableDataDetection() {
        isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        self.attributedText = attributedTextWithLinks()
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
