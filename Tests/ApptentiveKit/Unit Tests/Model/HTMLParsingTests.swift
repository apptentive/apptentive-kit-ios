//
//  HTMLParsingTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 4/9/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing
import UIKit

@testable import ApptentiveKit

struct HTMLParsingTests {

    @Test func testBasicStyling() async throws {
        let html = "<html><b>Bold <i>Italic</i></b> <u>underline</u></html>"

        let attributedString = SimpleHTMLParser.parseHTML(html)
        let nsAttributedString = NSAttributedString(attributedString)

        var counter = 0
        nsAttributedString.enumerateAttribute(.font, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
            defer {
                counter += 1
            }

            guard let font = value as? UIFont else {
                return
            }

            let traits = font.fontDescriptor.symbolicTraits

            switch counter {
            case 0:
                #expect(traits.contains(.traitBold))
            case 1:
                #expect(traits.contains(.traitBold) && traits.contains(.traitItalic))
            default:
                #expect(traits.isEmpty)
            }
        }

        #expect(counter == 3)
    }

    @Test func testLinks() async throws {
        let html = "<html><a href=\"https://www.example.com/\">This</a> is a link.</html>"

        let attributedString = SimpleHTMLParser.parseHTML(html)
        let nsAttributedString = NSAttributedString(attributedString)

        var counter = 0
        nsAttributedString.enumerateAttribute(.link, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
            defer {
                counter += 1
            }

            switch counter {
            case 0:
                #expect((value as? URL)?.absoluteString == "https://www.example.com/")

            default:
                #expect(value == nil)
            }
        }

        #expect(counter == 2)
    }

    @Test func testStrikethrough() async throws {
        let html = "<html><s>This is a strikethrough</s>, this is not.</html>"

        let attributedString = SimpleHTMLParser.parseHTML(html)
        let nsAttributedString = NSAttributedString(attributedString)

        var counter = 0
        nsAttributedString.enumerateAttribute(.strikethroughStyle, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
            defer {
                counter += 1
            }

            switch counter {
            case 0:
                #expect(value as? Int == NSUnderlineStyle.single.rawValue)

            default:
                #expect(value == nil)
            }
        }

        #expect(counter == 2)
    }

    @Test func testOrderedListItems() async throws {
        let html = "<html><ol><li>One</li><li>Two</li></ol></html>"

        let attributedString = SimpleHTMLParser.parseHTML(html)
        let nsAttributedString = NSAttributedString(attributedString)

        var counter = 0
        nsAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
            defer {
                counter += 1
            }

            guard let paragraphStyle = value as? NSParagraphStyle else {
                return
            }

            switch counter {
            case 0:
                #expect(paragraphStyle.textLists.first?.markerFormat == .decimal)
            case 2:
                #expect(paragraphStyle.textLists.first?.markerFormat == .decimal)
            default:
                return
            }
        }

        #expect(counter == 4)
    }

    @Test func testUnorderedListItems() async throws {
        let html = "<html><ul><li>One</li><li>Two</li></ul></html>"

        let attributedString = SimpleHTMLParser.parseHTML(html)
        let nsAttributedString = NSAttributedString(attributedString)

        var counter = 0
        nsAttributedString.enumerateAttribute(.paragraphStyle, in: NSRange(location: 0, length: nsAttributedString.length), options: []) { value, range, _ in
            defer {
                counter += 1
            }

            guard let paragraphStyle = value as? NSParagraphStyle else {
                return
            }

            switch counter {
            case 0:
                #expect(paragraphStyle.textLists.first?.markerFormat == .disc)
            case 2:
                #expect(paragraphStyle.textLists.first?.markerFormat == .disc)
            default:
                return
            }
        }

        #expect(counter == 4)
    }

}
