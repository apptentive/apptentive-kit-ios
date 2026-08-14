//
//  QLPreviewRepresentable.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import QuickLook
import SwiftUI

/// SwiftUI wrapper around `QLPreviewController`, embedded in a `UINavigationController`.
/// QuickLook only injects its own Done button when it is the directly-presented controller,
/// so embedded in our navigation controller we add an explicit close (X) button to match the
/// Message Center toolbar. Reads its items from `viewModel.previewItems` and dismisses by
/// clearing `viewModel.showPreview`; swipe-to-dismiss continues to work alongside the button.
struct QLPreviewRepresentable: UIViewControllerRepresentable {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    func makeUIViewController(context: Context) -> UINavigationController {
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        preview.delegate = context.coordinator

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: context.coordinator,
            action: #selector(Coordinator.closePreview))
        closeButton.accessibilityLabel = viewModel.closeButtonAccessibilityLabel
        closeButton.accessibilityIdentifier = "previewCloseButton"
        preview.navigationItem.leftBarButtonItem = closeButton

        return UINavigationController(rootViewController: preview)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        context.coordinator.items = viewModel.previewItems
        if let preview = uiViewController.viewControllers.first as? QLPreviewController {
            preview.reloadData()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, items: viewModel.previewItems)
    }

    final class Coordinator: NSObject, QLPreviewControllerDataSource, @MainActor QLPreviewControllerDelegate {
        let viewModel: MessageCenterSwiftUIViewModel
        var items: [MessageCenterViewModel.Message.Attachment]

        init(viewModel: MessageCenterSwiftUIViewModel, items: [MessageCenterViewModel.Message.Attachment]) {
            self.viewModel = viewModel
            self.items = items
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            items.count
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            items[index]
        }

        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            dismiss()
        }

        /// Explicit close-button path. Dismissing the SwiftUI sheet via `showPreview` does
        /// not fire `previewControllerDidDismiss`, so the button must clear state itself.
        @objc func closePreview() {
            dismiss()
        }

        private func dismiss() {
            Task { @MainActor in
                viewModel.showPreview = false
                viewModel.previewItems = []
            }
        }
    }
}
