import Foundation
import UIKit

class SimpleHTMLParser {
    enum HTMLTag: String {
        case bold = "b"
        case strong = "strong"
        case italic = "i"
        case emphasis = "em"
        case underline = "u"
        case strikethrough = "s"
        case listItem = "li"
        case unorderedList = "ul"
        case orderedList = "ol"
        case paragraph = "p"
        case div = "div"
        case span = "span"
        case br = "br"
        case link = "a"

        var attributes: [NSAttributedString.Key: Any] {
            switch self {
            case .bold, .strong:
                return [.font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)]
            case .italic, .emphasis:
                return [.font: UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)]
            case .underline:
                return [.underlineStyle: NSUnderlineStyle.single.rawValue]
            case .strikethrough:
                return [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            case .link:
                return [.foregroundColor: UIColor.systemBlue]
            default:
                return [:]
            }
        }

        var fontTraits: UIFontDescriptor.SymbolicTraits {
            switch self {
            case .bold, .strong:
                return .traitBold
            case .italic, .emphasis:
                return .traitItalic
            default:
                return []
            }
        }
    }

    struct TagStack {
        var currentAttributes: [NSAttributedString.Key: Any] = [:]
        var tags: [HTMLTag] = []
        var listLevel = 0
        var isOrderedList = false
        var listItemCount = 0
        var currentURL: URL? = nil
        var fontTraits: UIFontDescriptor.SymbolicTraits = []

        mutating func pushTag(_ tag: HTMLTag, attributes: [String: String] = [:]) {
            tags.append(tag)

            // Handle font traits (bold/italic) separately for proper nesting
            if !tag.fontTraits.isEmpty {
                fontTraits.insert(tag.fontTraits)
                updateFont()
            }

            // Update other attributes based on the tag
            for (key, value) in tag.attributes {
                if key != .font {  // Skip font as we handle it separately
                    currentAttributes[key] = value
                }
            }

            // Handle special attributes
            if tag == .link, let hrefValue = attributes["href"], let url = URL(string: hrefValue) {
                currentURL = url
                currentAttributes[.link] = url
            }

            // Handle list tracking
            switch tag {
            case .unorderedList:
                listLevel += 1
                isOrderedList = false
            case .orderedList:
                listLevel += 1
                isOrderedList = true
                listItemCount = 0
            case .listItem:
                listItemCount += 1
            default:
                break
            }
        }

        mutating func popTag(_ tag: HTMLTag) {
            if let index = tags.lastIndex(of: tag) {
                tags.remove(at: index)

                // Handle list tracking
                switch tag {
                case .unorderedList, .orderedList:
                    listLevel -= 1
                    if listLevel < 0 {
                        listLevel = 0
                    }
                case .link:
                    // Remove the link from attributes
                    currentAttributes.removeValue(forKey: .link)
                    currentURL = nil
                default:
                    break
                }

                // Remove font trait if it was applied by this tag
                if !tag.fontTraits.isEmpty {
                    fontTraits.remove(tag.fontTraits)
                    updateFont()
                }

                // Update other attributes
                for key in tag.attributes.keys {
                    if key != .font {  // Skip font as we handle it separately
                        currentAttributes.removeValue(forKey: key)
                    }
                }

                // Reapply attributes from remaining tags
                for remainingTag in tags {
                    for (key, value) in remainingTag.attributes {
                        if key != .font {  // Skip font as we handle it separately
                            currentAttributes[key] = value
                        }
                    }
                }

                // Restore link attribute if still in a link tag
                if tags.contains(.link), let url = currentURL {
                    currentAttributes[.link] = url
                }
            }
        }

        mutating func updateFont() {
            // Start with system font
            var font = UIFont.systemFont(ofSize: UIFont.systemFontSize)

            // If we have any font traits, apply them
            if !fontTraits.isEmpty {
                if let descriptor = font.fontDescriptor.withSymbolicTraits(fontTraits) {
                    font = UIFont(descriptor: descriptor, size: UIFont.systemFontSize)
                }
            }

            currentAttributes[.font] = font
        }
    }

    static func parseHTML(_ html: String) -> AttributedString {
        var result = AttributedString()
        var tagStack = TagStack()
        var currentText = ""
        var index = html.startIndex

        let tabStopOptions: [NSTextTab.OptionKey: Any] = [:]
        let indentation = 8.0
        let tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: tabStopOptions),
            NSTextTab(textAlignment: .left, location: 32.0, options: tabStopOptions),
        ]

        let unorderedListParagraphStyle = NSMutableParagraphStyle()

        unorderedListParagraphStyle.tabStops = tabStops
        unorderedListParagraphStyle.defaultTabInterval = indentation
        unorderedListParagraphStyle.lineSpacing = 0
        unorderedListParagraphStyle.paragraphSpacing = 0
        unorderedListParagraphStyle.headIndent = indentation
        unorderedListParagraphStyle.textLists = [.init(markerFormat: .disc, options: 0)]

        let orderedListParagraphStyle = NSMutableParagraphStyle()

        orderedListParagraphStyle.tabStops = tabStops
        orderedListParagraphStyle.defaultTabInterval = indentation
        orderedListParagraphStyle.lineSpacing = 0
        orderedListParagraphStyle.paragraphSpacing = 0
        orderedListParagraphStyle.headIndent = indentation
        orderedListParagraphStyle.textLists = [.init(markerFormat: .decimal, options: 0)]

        // Process the HTML character by character
        while index < html.endIndex {
            let char = html[index]

            if char == "<" {
                // Save the current text with current attributes
                if !currentText.isEmpty {
                    result.append(AttributedString(currentText, attributes: AttributeContainer(tagStack.currentAttributes)))
                    currentText = ""
                }

                // Find the end of the tag
                if let tagEndIndex = html[index...].firstIndex(of: ">") {
                    let tagContent = String(html[html.index(after: index)..<tagEndIndex])

                    if tagContent.hasPrefix("/") {
                        // Closing tag
                        let tagName = String(tagContent.dropFirst())
                        if let tag = HTMLTag(rawValue: tagName) {
                            tagStack.popTag(tag)
                        }
                    } else if tagContent == "br" || tagContent == "br/" {
                        // Line break
                        result.append(AttributedString("\n"))
                    } else {
                        // Opening tag - parse attributes
                        let components = tagContent.components(separatedBy: .whitespaces)
                        if let firstComponent = components.first, let tag = HTMLTag(rawValue: firstComponent) {
                            // Parse attributes for this tag
                            var tagAttributes: [String: String] = [:]

                            // Simple attribute parser
                            var attrText = tagContent.dropFirst(firstComponent.count).trimmingCharacters(in: .whitespaces)
                            while !attrText.isEmpty {
                                // Find attribute name
                                guard let equalIndex = attrText.firstIndex(of: "=") else { break }
                                let attrName = attrText[..<equalIndex].trimmingCharacters(in: .whitespaces)

                                // Find attribute value
                                var valueStartIndex = attrText.index(after: equalIndex)
                                while valueStartIndex < attrText.endIndex && attrText[valueStartIndex].isWhitespace {
                                    valueStartIndex = attrText.index(after: valueStartIndex)
                                }

                                if valueStartIndex < attrText.endIndex {
                                    let quote = attrText[valueStartIndex]
                                    if quote == "\"" || quote == "'" {
                                        // Find closing quote
                                        valueStartIndex = attrText.index(after: valueStartIndex)
                                        if let valueEndIndex = attrText[valueStartIndex...].firstIndex(of: quote) {
                                            let attrValue = String(attrText[valueStartIndex..<valueEndIndex])
                                            tagAttributes[String(attrName)] = attrValue

                                            // Move past this attribute
                                            attrText = attrText[attrText.index(after: valueEndIndex)...].trimmingCharacters(in: .whitespaces)
                                        } else {
                                            // No closing quote found, just take the rest
                                            let attrValue = String(attrText[valueStartIndex...])
                                            tagAttributes[String(attrName)] = attrValue
                                            attrText = ""
                                        }
                                    } else {
                                        // No quotes, find next whitespace
                                        if let valueEndIndex = attrText[valueStartIndex...].firstIndex(where: { $0.isWhitespace }) {
                                            let attrValue = String(attrText[valueStartIndex..<valueEndIndex])
                                            tagAttributes[String(attrName)] = attrValue

                                            // Move past this attribute
                                            attrText = attrText[valueEndIndex...].trimmingCharacters(in: .whitespaces)
                                        } else {
                                            // No whitespace, just take the rest
                                            let attrValue = String(attrText[valueStartIndex...])
                                            tagAttributes[String(attrName)] = attrValue
                                            attrText = ""
                                        }
                                    }
                                } else {
                                    break
                                }
                            }

                            tagStack.pushTag(tag, attributes: tagAttributes)

                            // Handle list items
                            if tag == .listItem {
                                let prefix: String
                                let paragraphStyle: NSParagraphStyle
                                if tagStack.isOrderedList {
                                    prefix = "\(tagStack.listItemCount).\t"
                                    paragraphStyle = orderedListParagraphStyle
                                } else {
                                    prefix = "•\t"
                                    paragraphStyle = unorderedListParagraphStyle
                                }
                                let tabs = String(repeating: "\t", count: tagStack.listLevel)
                                result.append(AttributedString("\n" + tabs + prefix, attributes: AttributeContainer([.paragraphStyle: paragraphStyle])))
                            } else if tag == .paragraph || tag == .div {
                                if result.characters.count > 0 {
                                    result.append(AttributedString("\n"))
                                }
                            }
                        }
                    }

                    index = html.index(after: tagEndIndex)
                } else {
                    // Malformed HTML, treat < as literal
                    currentText.append(char)
                    index = html.index(after: index)
                }
            } else if char == "&" {
                // Handle HTML entities
                if let semicolonIndex = html[index...].firstIndex(of: ";") {
                    let entity = String(html[html.index(after: index)..<semicolonIndex])

                    switch entity {
                    case "amp":
                        currentText.append("&")
                    case "lt":
                        currentText.append("<")
                    case "gt":
                        currentText.append(">")
                    case "quot":
                        currentText.append("\"")
                    case "apos":
                        currentText.append("'")
                    case "nbsp":
                        currentText.append(" ")
                    default:
                        // Handle numeric entities
                        if entity.hasPrefix("#") {
                            var charCode = 0
                            let codeString = String(entity.dropFirst())

                            if codeString.hasPrefix("x") {
                                // Hex code
                                if let code = Int(codeString.dropFirst(), radix: 16) {
                                    charCode = code
                                }
                            } else {
                                // Decimal code
                                if let code = Int(codeString) {
                                    charCode = code
                                }
                            }

                            if charCode > 0, let scalar = UnicodeScalar(charCode) {
                                currentText.append(Character(scalar))
                            }
                        } else {
                            // Unknown entity, leave as is
                            currentText.append("&\(entity);")
                        }
                    }

                    index = html.index(after: semicolonIndex)
                } else {
                    // Malformed entity, treat & as literal
                    currentText.append(char)
                    index = html.index(after: index)
                }
            } else {
                // Regular character
                currentText.append(char)
                index = html.index(after: index)
            }
        }

        // Add any remaining text
        if !currentText.isEmpty {
            result.append(AttributedString(currentText, attributes: AttributeContainer(tagStack.currentAttributes)))
        }

        return result
    }
}
