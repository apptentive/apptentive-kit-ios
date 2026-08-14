//
//  PHPickerRepresentable.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import OSLog
@preconcurrency import PhotosUI
import SwiftUI

/// SwiftUI wrapper around `PHPickerViewController`.
///
/// Limits selection to `remainingAttachmentSlots` images and forwards picks
/// to `viewModel.addImageAttachment(_:name:)`.
struct PHPickerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = viewModel.remainingAttachmentSlots
        configuration.filter = .images

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let viewModel: MessageCenterSwiftUIViewModel

        init(viewModel: MessageCenterSwiftUIViewModel) {
            self.viewModel = viewModel
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            Task { @MainActor in
                viewModel.showImagePicker = false
            }

            for result in results {
                result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                    guard let self else { return }

                    if let error {
                        Logger.messages.debug("Error selecting images from PHPicker: \(error).")
                    }

                    guard let image = object as? UIImage else {
                        Logger.messages.error("PHPickerViewController failed to provide picked image.")
                        return
                    }

                    Task { @MainActor in
                        do {
                            try await self.viewModel.addImageAttachment(image, name: result.itemProvider.suggestedName)
                        } catch {
                            Logger.messages.error("Unable to add attachment: \(error).")
                            self.viewModel.attachmentError = error
                        }
                    }
                }
            }
        }
    }
}
