//
//  GreetingHeaderViewSwiftUI.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Branding header for Message Center: 100×100 rounded image, title, and body.
/// Switches to a horizontal layout when vertical size class is `.compact` (landscape iPhone).
struct GreetingHeaderViewSwiftUI: View {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let imageSize: CGFloat = 100
    private let imageCornerRadius: CGFloat = 10
    private let spacing: CGFloat = 16

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                HStack(alignment: .center, spacing: spacing) {
                    image
                    textBlock
                }
            } else {
                VStack(alignment: .center, spacing: spacing) {
                    image
                    textBlock
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var image: some View {
        if let greetingImage = viewModel.greetingImage {
            Image(uiImage: greetingImage)
                .resizable()
                .scaledToFit()
                .frame(width: imageSize, height: imageSize)
                .clipShape(RoundedRectangle(cornerRadius: imageCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: imageCornerRadius)
                .fill(Color(uiColor: .secondarySystemFill))
                .frame(width: imageSize, height: imageSize)
        }
    }

    private var textBlock: some View {
        VStack(alignment: .center, spacing: spacing) {
            Text(viewModel.greetingTitle)
                .font(.apptentiveMessageCenterGreetingTitle)
                .foregroundStyle(Color.apptentiveMessageCenterGreetingTitle)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            DataDetectorTextView(
                text: viewModel.greetingBody,
                textColor: .apptentiveMessageCenterGreetingBody,
                textAlignment: .center
            )
        }
    }
}
