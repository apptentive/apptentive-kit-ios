//
//  ComposeBarViewSwiftUI.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Compose bar docked above the keyboard. Layout matches the UIKit `MessageCenterComposeView`:
/// HStack of [attach | text input | send] with the draft-attachment scroll row underneath.
/// On iOS 26+ the text container uses a tinted glass rounded rectangle (max-radius 26);
/// otherwise a rounded rectangle with a hairline border.
struct ComposeBarViewSwiftUI: View {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    @State private var showAttachmentOptions = false

    private let textInputMinHeight: CGFloat = 18
    private let textInputMaxHeight: CGFloat = 100
    private let textContainerCornerRadius: CGFloat = 6

    var body: some View {
        VStack(spacing: 0) {
            separator

            HStack(alignment: .center, spacing: 8) {
                attachButton
                textInputContainer
                sendButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if !viewModel.draftAttachments.isEmpty {
                draftAttachmentsRow
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.draftAttachments.count)
        .confirmationDialog(
            viewModel.attachmentOptionsTitle,
            isPresented: $showAttachmentOptions,
            titleVisibility: .visible
        ) {
            Button(viewModel.attachmentOptionsImagesButton) {
                viewModel.showImagePicker = true
            }
            Button(viewModel.attachmentOptionsFilesButton) {
                viewModel.showFilePicker = true
            }
            Button(viewModel.attachmentOptionsCancelButton, role: .cancel) {}
        }
    }

    @ViewBuilder
    private var separator: some View {
        if #available(iOS 26, *) {
            EmptyView()
        } else {
            Color.apptentiveMessageCenterComposeBoxSeparator
                .frame(height: 1 / UIScreen.main.scale)
        }
    }

    private var attachButton: some View {
        Button {
            showAttachmentOptions = true
        } label: {
            Image.apptentiveMessageAttachmentButton
                .font(.system(size: glyphPointSize))
        }
        .apptentiveComposeButtonStyle()
        .tint(Color.apptentiveTint)
        .disabled(!viewModel.canAddAttachment)
        .accessibilityLabel(viewModel.attachButtonAccessibilityLabel)
        .accessibilityHint(viewModel.showAttachmentButtonAccessibilityHint)
        .accessibilityIdentifier("attachmentButton")
    }

    private var sendButton: some View {
        Button {
            Task {
                do {
                    try await viewModel.sendMessage()
                } catch {
                    viewModel.sendError = error
                }
            }
        } label: {
            Image.apptentiveMessageSendButton
                .font(.system(size: glyphPointSize))
        }
        .apptentiveComposeButtonStyle()
        .tint(Color.apptentiveTint)
        .disabled(!viewModel.canSendMessage)
        .scaleEffect(viewModel.canSendMessage ? 1.0 : 0.9)
        .opacity(viewModel.canSendMessage ? 1.0 : 0.6)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.canSendMessage)
        .accessibilityLabel(viewModel.sendButtonAccessibilityLabel)
        .accessibilityHint(viewModel.sendButtonAccessibilityHint)
        .accessibilityIdentifier("sendButton")
    }

    private var glyphPointSize: CGFloat {
        if #available(iOS 26, *) { 20 } else { 24 }
    }

    private var textInputContainer: some View {
        ZStack(alignment: .topLeading) {
            composeInput
                .padding(.horizontal, textInputHorizontalPadding)
                .padding(.vertical, textInputVerticalPadding)

            if viewModel.draftMessageBody.isEmpty {
                Text(viewModel.composerPlaceholderText)
                    .font(Font(ComposeTextInputRepresentable.cappedFont()))
                    .foregroundStyle(Color.apptentiveMessageCenterTextInputPlaceholder)
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.horizontal, textInputHorizontalPadding)
                    .padding(.vertical, textInputVerticalPadding)
                    .allowsHitTesting(false)
            }
        }
        .apptentiveInputBackground(cornerRadius: textContainerCornerRadius)
    }

    /// On iOS 26 the glass capsule needs generous breathing room so the text
    /// doesn't crowd the rounded ends; pre-26 keeps tighter values to suit the
    /// rounded-rectangle border.
    private var textInputHorizontalPadding: CGFloat {
        if #available(iOS 26, *) { 12 } else { 10 }
    }

    private var textInputVerticalPadding: CGFloat {
        if #available(iOS 26, *) { 10 } else { 8 }
    }

    /// On iOS 16+, `ComposeTextInputRepresentable.sizeThatFits(_:uiView:context:)`
    /// drives sizing correctly. On iOS 15 that hook doesn't exist, so SwiftUI
    /// stretches the representable to the full proposed height — `.fixedSize`
    /// forces it to use the clamped `intrinsicContentSize` instead.
    @ViewBuilder
    private var composeInput: some View {
        let input = ComposeTextInputRepresentable(
            text: $viewModel.draftMessageBody,
            minHeight: textInputMinHeight,
            maxHeight: textInputMaxHeight
        )

        if #available(iOS 16.0, *) {
            input
        } else {
            input.fixedSize(horizontal: false, vertical: true)
        }
    }

    private var draftAttachmentsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(viewModel.draftAttachments.enumerated()), id: \.element.localURL) { index, attachment in
                    DraftAttachmentViewSwiftUI(
                        attachment: attachment,
                        onRemove: {
                            Task {
                                try? await viewModel.removeAttachment(at: index)
                            }
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.6).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
