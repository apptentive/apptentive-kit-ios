//
//  AttachmentThumbnailView.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// 55×55 square attachment thumbnail (no rounded corners) with a circular download-progress
/// overlay and a tap action. The image is center-cropped via `.scaledToFill()` + `.clipped()`
/// so it fills the square exactly without bleeding past its frame onto adjacent thumbnails.
struct AttachmentThumbnailView: View {
    let attachment: MessageCenterViewModel.Message.Attachment
    let openHint: String
    let downloadHint: String
    let onTap: () -> Void

    private let size: CGFloat = 55

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = attachment.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image.apptentiveAttachmentPlaceholder
                        .resizable(capInsets: EdgeInsets(top: 14, leading: 4, bottom: 4, trailing: 14))

                    Text(attachment.fileExtension?.uppercased() ?? "FILE")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.apptentiveTint)
                        .multilineTextAlignment(.center)
                        .padding(4)
                }

                if attachment.downloadProgress > 0 && attachment.downloadProgress < 1 {
                    ProgressView(value: attachment.downloadProgress)
                        .progressViewStyle(.circular)
                }
            }
            .frame(width: size, height: size)
            .clipped()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(attachment.viewButtonAccessibilityLabel)
        .accessibilityHint(attachment.localURL != nil ? openHint : downloadHint)
    }
}
