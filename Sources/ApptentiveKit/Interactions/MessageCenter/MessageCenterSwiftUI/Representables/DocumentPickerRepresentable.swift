//
//  DocumentPickerRepresentable.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import OSLog
import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI wrapper around `UIDocumentPickerViewController`. Opens with the
/// `viewModel.allUTTypes` filter set and forwards picks to
/// `viewModel.addFileAttachment(at:)`.
struct DocumentPickerRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: viewModel.allUTTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let viewModel: MessageCenterSwiftUIViewModel

        init(viewModel: MessageCenterSwiftUIViewModel) {
            self.viewModel = viewModel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            Task { @MainActor in
                viewModel.showFilePicker = false

                guard let url = urls.first else { return }
                do {
                    try await viewModel.addFileAttachment(at: url)
                } catch {
                    Logger.messages.error("Unable to add attachment: \(error).")
                    viewModel.attachmentError = error
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            Task { @MainActor in
                viewModel.showFilePicker = false
            }
        }
    }
}
