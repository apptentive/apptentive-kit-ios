//
//  SentMessageRow.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/12/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Trailing-aligned outbound bubble for messages sent from the device.
/// Contains optional body text, optional attachment thumbnails, and a status caption.
struct SentMessageRow: View {
    let message: MessageCenterViewModel.Message
    let indexPath: IndexPath
    let maxBubbleWidth: CGFloat
    let openHint: String
    let downloadHint: String
    let onAttachmentTap: (Int) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 0)
            bubble
                .frame(maxWidth: maxBubbleWidth, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .id("msg-\(indexPath.section)-\(indexPath.row)")
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.accessibilityLabel ?? "")
        .accessibilityHint(message.accessibilityHint ?? "")
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let body = message.body, !body.isEmpty {
                DataDetectorTextView(
                    text: body,
                    textColor: .apptentiveMessageLabelOutbound
                )
            }

            if !message.attachments.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(message.attachments.enumerated()), id: \.offset) { index, attachment in
                        AttachmentThumbnailView(
                            attachment: attachment,
                            openHint: openHint,
                            downloadHint: downloadHint
                        ) {
                            onAttachmentTap(index)
                        }
                    }
                }
                .padding(.top, (message.body?.isEmpty ?? true) ? 6 : 0)
            }

            if !message.statusText.isEmpty {
                Text(message.statusText)
                    .font(.caption)
                    .foregroundStyle(Color.apptentiveMessageLabelOutbound)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 42))
        .background(
            Image.apptentiveSentMessageBubble.foregroundStyle(Color.apptentiveMessageBubbleOutbound)
        )
    }
}
