//
//  DraftAttachmentViewSwiftUI.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// 64×64 draft attachment thumbnail with a remove button overlaid at the top-leading corner.
struct DraftAttachmentViewSwiftUI: View {
    let attachment: MessageCenterViewModel.Message.Attachment
    let onRemove: () -> Void

    private let size: CGFloat = 64
    private let cornerRadius: CGFloat = 8
    private let removeButtonSize: CGFloat = 22

    var body: some View {
        thumbnail
            .overlay(alignment: .topLeading) {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color(uiColor: .apptentiveAttachmentRemoveButton))
                        .font(.system(size: removeButtonSize))
                }
                .offset(x: -removeButtonSize / 2, y: -removeButtonSize / 2)
                .accessibilityLabel(Text(attachment.removeButtonAccessibilityLabel))
            }
            .padding(.top, removeButtonSize / 2)
            .padding(.leading, removeButtonSize / 2)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnail = attachment.thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(uiColor: .secondarySystemFill))
                .frame(width: size, height: size)
                .overlay {
                    Text(attachment.fileExtension?.uppercased() ?? "FILE")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
        }
    }
}
