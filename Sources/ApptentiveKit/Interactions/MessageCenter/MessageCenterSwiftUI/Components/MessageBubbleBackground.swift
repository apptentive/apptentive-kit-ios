//
//  MessageBubbleBackground.swift
//  ApptentiveKit
//
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Chat bubble background that keeps the tail on the correct side in right-to-left languages.
///
/// The bubble assets and their cap insets are authored for left-to-right. Rendering them in a forced
/// left-to-right environment prevents the implicit asset flip (which would desynchronize the image from
/// its cap insets), and the result is then mirrored explicitly when the real layout direction is right-to-left.
struct MessageBubbleBackground: View {
    let image: Image
    let color: Color

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        image
            .foregroundStyle(color)
            .environment(\.layoutDirection, .leftToRight)
            .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1, y: 1)
            .accessibilityHidden(true)
    }
}
