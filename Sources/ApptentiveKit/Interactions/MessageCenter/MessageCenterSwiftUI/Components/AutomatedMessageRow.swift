//
//  AutomatedMessageRow.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/12/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Leading-aligned inbound bubble for automated / contextual messages.
struct AutomatedMessageRow: View {
    let message: MessageCenterViewModel.Message
    let indexPath: IndexPath
    let maxBubbleWidth: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            bubble
                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .id("msg-\(indexPath.section)-\(indexPath.row)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.accessibilityLabel ?? "")
        .accessibilityHint(message.accessibilityHint ?? "")
    }

    private var bubble: some View {
        DataDetectorTextView(
            text: message.body ?? "",
            textColor: .apptentiveMessageLabelInbound
        )
        .padding(EdgeInsets(top: 12, leading: 42, bottom: 12, trailing: 16))
        .background(
            Image.apptentiveReceivedMessageBubble.foregroundStyle(Color.apptentiveMessageBubbleInbound)
        )
    }
}
