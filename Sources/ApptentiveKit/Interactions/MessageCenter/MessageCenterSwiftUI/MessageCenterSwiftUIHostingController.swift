//
//  MessageCenterSwiftUIHostingController.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Hosts the SwiftUI `MessageCenterSwiftUIView` and owns the `MessageCenterSwiftUIViewModel`
/// bridge for its lifetime. Constructed by `InteractionPresenter.presentMessageCenter(with:)`
/// as a drop-in replacement for `MessageCenterViewController`.
final class MessageCenterSwiftUIHostingController: UIHostingController<MessageCenterSwiftUIView> {
    private let swiftUIViewModel: MessageCenterSwiftUIViewModel

    init(viewModel: MessageCenterViewModel) {
        let adapter = MessageCenterSwiftUIViewModel(base: viewModel)
        self.swiftUIViewModel = adapter
        super.init(rootView: MessageCenterSwiftUIView(viewModel: adapter))

        adapter.onRequestDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
