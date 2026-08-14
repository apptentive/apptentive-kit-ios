//
//  SwiftUI+Apptentive.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import Combine
import SwiftUI

// MARK: - Color
//
// Native SwiftUI values, independent of the Apptentive `UIColor` extensions.
//
// For the three UIKit system semantic colors that SwiftUI does not expose as static
// properties on the iOS 15 baseline (`systemBackground`, `placeholderText`, `separator`),
// we bridge through `Color(uiColor:)` so dark-mode adaptivity is preserved. Those
// bridges depend only on UIKit framework symbols.

extension Color {
    public static var apptentiveTint: Color { .accentColor }

    public static var apptentiveError: Color { .red }

    public static var apptentiveMessageLabelInbound: Color { .white }
    public static var apptentiveMessageLabelOutbound: Color { .white }

    /// Bright blue used by the legacy UIKit `apptentiveMessageBubbleOutbound`.
    public static var apptentiveMessageBubbleOutbound: Color {
        Color(red: 0, green: 0.42, blue: 1)
    }

    /// Mid-gray matching `UIColor.darkGray` (RGB ~0.333).
    ///
    /// Non-adaptive in UIKit too.
    public static var apptentiveMessageBubbleInbound: Color {
        Color(red: 1.0 / 3.0, green: 1.0 / 3.0, blue: 1.0 / 3.0)
    }

    public static var apptentiveMessageCenterTextInput: Color { .primary }

    /// Bridges to the themeable `UIColor.apptentiveMessageCenterTextInputPlaceholder` (an
    /// exception to this file's usual "native SwiftUI value" rule) so integrators who
    /// customize that color via the asset catalog or theme config see it reflected here
    /// too, and so this matches UIKit's dedicated `.placeholderText`-based default instead
    /// of the more prominent `.secondary`.
    @MainActor public static var apptentiveMessageCenterTextInputPlaceholder: Color { Color(uiColor: .apptentiveMessageCenterTextInputPlaceholder) }

    public static var apptentiveMessageCenterGreetingTitle: Color { .secondary }

    public static var apptentiveTextInputBackground: Color { Color(uiColor: .systemBackground) }
    public static var apptentiveMessageCenterTextInputBackground: Color { Color(uiColor: .systemBackground) }
    public static var apptentiveMessageCenterComposeBoxSeparator: Color { Color(uiColor: .separator) }

    public static var apptentiveMessageCenterTextInputBorder: Color {
        if #available(iOS 26, *) {
            return .clear
        } else {
            return Color(uiColor: .lightGray)
        }
    }
}

// MARK: - Font

extension Font {
    public static var apptentiveInstructionsLabel: Font { .footnote }
    public static var apptentiveMessageCenterTextInput: Font { .body }
    public static var apptentiveMessageCenterTextInputPlaceholder: Font { .body }
    public static var apptentiveMessageCenterGreetingTitle: Font { .headline }
}

// MARK: - View modifiers

/// Applies the standard Apptentive text-input container chrome to a view: a tinted
/// glass rounded rectangle (max-radius 26, matching UIKit's `.capsule(maximumRadius: 26)`)
/// on iOS 26+, otherwise a rounded-rectangle fill plus a hairline stroke.
///
/// Defaults match the Message Center compose bar; profile fields override `fill` and
/// `cornerRadius` to match their counterparts.
struct ApptentiveInputBackground: ViewModifier {
    let fill: Color
    let stroke: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(
                .regular.tint(Color(uiColor: .secondarySystemGroupedBackground)),
                in: RoundedRectangle(cornerRadius: 26, style: .continuous)
            )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(stroke, lineWidth: 1 / UIScreen.main.scale)
                )
        }
    }
}

extension View {
    /// Standard Apptentive text-input container chrome (glass on iOS 26+, otherwise
    /// rounded rectangle with hairline border).
    ///
    /// Used by the compose bar and the profile name/email fields.
    func apptentiveInputBackground(
        fill: Color = .apptentiveMessageCenterTextInputBackground,
        stroke: Color = .apptentiveMessageCenterTextInputBorder,
        cornerRadius: CGFloat = 6
    ) -> some View {
        modifier(ApptentiveInputBackground(fill: fill, stroke: stroke, cornerRadius: cornerRadius))
    }

    /// Applies the prominent-glass button style on iOS 26+ to match UIKit's
    /// `MessageCenterGlassComposeView` (`.prominentGlass()`).
    ///
    /// On older OSes the existing `.circle.fill` SF symbols already provide the filled-circle look.
    func apptentiveComposeButtonStyle() -> some View {
        modifier(ApptentiveComposeButtonStyle())
    }

    /// Background chrome for the compose bar matching the UIKit container:
    /// transparent on iOS 26+ (system glass chrome handles it) and
    /// `systemBackground` on older OSes (`apptentiveMessageCenterComposeBoxBackground`).
    func apptentiveComposeBarBackground() -> some View {
        modifier(ApptentiveComposeBarBackground())
    }

    /// `onChange(of:)` that compiles without deprecation on the iOS 15 floor and on the iOS 17+ SDK.
    ///
    /// The single-closure `onChange(of:perform:)` is deprecated in iOS 17; the two-closure
    /// form doesn't exist before it. Used for observing non-`@Published`, derived values (where
    /// `onReceive` of a publisher isn't available).
    @ViewBuilder
    func onChangeCompat<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.onChange(of: value) { _, newValue in action(newValue) }
        } else {
            self.onChange(of: value, perform: action)
        }
    }

    /// Publisher that informs subscribers of keyboard show/hide events, emitting `true` for show and `false` for hide.
    var keyboardPublisher: AnyPublisher<Bool, Never> {
        Publishers
            .Merge(
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillShowNotification)
                    .map { _ in true },
                NotificationCenter
                    .default
                    .publisher(for: UIResponder.keyboardWillHideNotification)
                    .map { _ in false }
            )
            .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
            .eraseToAnyPublisher()
    }
}

struct ApptentiveComposeButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
        } else {
            content
        }
    }
}

struct ApptentiveComposeBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
        } else {
            content.background(Color(uiColor: .systemBackground))
        }
    }
}

// MARK: - Image

@MainActor
extension Image {
    /// The image to use for the attach-attachment button in the Message Center compose bar.
    ///
    /// On iOS 26+ uses the lightweight `paperclip` glyph; otherwise the filled circle variant.
    public static var apptentiveMessageAttachmentButton: Image {
        if #available(iOS 26, *) {
            return Image(systemName: "paperclip")
        } else {
            return Image(systemName: "paperclip.circle.fill")
        }
    }

    /// The image to use for the send button in the Message Center compose bar.
    /// On iOS 26+ uses the lightweight `paperplane` glyph; otherwise the filled circle variant.
    public static var apptentiveMessageSendButton: Image {
        if #available(iOS 26, *) {
            return Image(systemName: "paperplane")
        } else {
            return Image(systemName: "paperplane.circle.fill")
        }
    }

    /// The image to use as the chat bubble for outbound messages.
    public static var apptentiveSentMessageBubble = Image("messageSentBubble", bundle: .apptentive)
        .renderingMode(.template)
        .resizable(capInsets: EdgeInsets(top: 26, leading: 26, bottom: 26, trailing: 52))

    /// The image to use as the chat bubble for inbound messages.
    public static var apptentiveReceivedMessageBubble = Image("messageReceivedBubble", bundle: .apptentive)
        .renderingMode(.template)
        .resizable(capInsets: EdgeInsets(top: 26, leading: 52, bottom: 26, trailing: 26))

    /// The image to use for attachment placeholders in messages and the composer.
    public static var apptentiveAttachmentPlaceholder = Image("document", bundle: .apptentive)
        .resizable(capInsets: EdgeInsets(top: 14, leading: 4, bottom: 4, trailing: 14))
}
