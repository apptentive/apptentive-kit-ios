//
//  ReceivedMessageRow.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/12/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Leading-aligned inbound bubble for messages from a human agent.
/// Shows a 22pt circular avatar, sender name, body, optional attachments, and a timestamp.
struct ReceivedMessageRow: View {
    let message: MessageCenterViewModel.Message
    let indexPath: IndexPath
    let maxBubbleWidth: CGFloat
    let openHint: String
    let downloadHint: String
    let onAppear: () -> Void
    let loadAvatar: () async -> UIImage?
    let onAttachmentTap: (Int) -> Void

    @State private var avatar: UIImage?

    private let avatarSize: CGFloat = 22

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            avatarView
            bubble
                .frame(maxWidth: maxBubbleWidth, alignment: .leading)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .id("msg-\(indexPath.section)-\(indexPath.row)")
        .task(id: indexPath) {
            // Downsample to display size so a multi-megapixel source doesn't sit
            // decoded in memory at full resolution for a 22pt circle.
            let raw = await loadAvatar()
            let target = CGSize(width: avatarSize, height: avatarSize)
            avatar = raw?.preparingThumbnail(of: target) ?? raw
        }
        .onAppear { onAppear() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.accessibilityLabel ?? "")
        .accessibilityHint(message.accessibilityHint ?? "")
    }

    @ViewBuilder
    private var avatarView: some View {
        if let avatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(uiColor: .secondarySystemFill))
                .frame(width: avatarSize, height: avatarSize)
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let name = message.sender?.name, !name.isEmpty {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(Color.apptentiveMessageLabelInbound)
            }

            if let body = message.body, !body.isEmpty {
                DataDetectorTextView(
                    text: body,
                    textColor: .apptentiveMessageLabelInbound
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
                .padding(.top, (message.sender?.name?.isEmpty ?? true) && (message.body?.isEmpty ?? true) ? 6 : 0)
            }

            if !message.statusText.isEmpty {
                Text(message.statusText)
                    .font(.caption)
                    .foregroundStyle(Color.apptentiveMessageLabelInbound)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 42, bottom: 12, trailing: 16))
        .background(
            Image.apptentiveReceivedMessageBubble.foregroundStyle(Color.apptentiveMessageBubbleInbound)
        )
    }
}
