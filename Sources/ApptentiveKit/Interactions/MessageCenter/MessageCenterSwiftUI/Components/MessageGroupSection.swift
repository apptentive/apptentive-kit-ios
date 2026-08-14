//
//  MessageGroupSection.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/12/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// A date-grouped section of messages: a centered date header followed by message rows.
/// Dispatches to the correct row type based on `message.direction`. Holds the view
/// model so leaf rows can be observation-free — actions are wired here as closures.
struct MessageGroupSection: View {
    let group: [MessageCenterViewModel.Message]
    let sectionIndex: Int
    let maxBubbleWidth: CGFloat
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    var body: some View {
        VStack(spacing: 0) {
            if let header = viewModel.dateStringForMessagesInGroup(at: sectionIndex) {
                Text(header)
                    .font(.footnote)
                    .foregroundStyle(Color(uiColor: .apptentiveMessageCenterStatus))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            ForEach(Array(group.enumerated()), id: \.element.nonce) { row, message in
                rowView(for: message, at: IndexPath(row: row, section: sectionIndex))
            }
        }
    }

    @ViewBuilder
    private func rowView(for message: MessageCenterViewModel.Message, at indexPath: IndexPath) -> some View {
        switch message.direction {
        case .automated:
            AutomatedMessageRow(
                message: message,
                indexPath: indexPath,
                maxBubbleWidth: maxBubbleWidth
            )
        case .sentFromDevice:
            SentMessageRow(
                message: message,
                indexPath: indexPath,
                maxBubbleWidth: maxBubbleWidth,
                openHint: viewModel.showAttachmentButtonAccessibilityHint,
                downloadHint: viewModel.downloadAttachmentButtonAccessibilityHint,
                onAttachmentTap: { index in
                    viewModel.openAttachment(at: index, in: message, indexPath: indexPath)
                }
            )
        case .sentFromDashboard:
            ReceivedMessageRow(
                message: message,
                indexPath: indexPath,
                maxBubbleWidth: maxBubbleWidth,
                openHint: viewModel.showAttachmentButtonAccessibilityHint,
                downloadHint: viewModel.downloadAttachmentButtonAccessibilityHint,
                onAppear: { viewModel.markMessageAsRead(at: indexPath) },
                loadAvatar: { try? await viewModel.getProfilePhoto(for: indexPath) },
                onAttachmentTap: { index in
                    viewModel.openAttachment(at: index, in: message, indexPath: indexPath)
                }
            )
        }
    }
}
