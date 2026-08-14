//
//  EditProfileRepresentable.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// SwiftUI wrapper around the existing `EditProfileViewController`, embedded in an
/// `ApptentiveNavigationController` so the Cancel / Save bar buttons appear as in
/// the legacy UIKit flow. Takes the underlying `MessageCenterViewModel` directly
/// because `EditProfileViewController` is constructed against that type.
struct EditProfileRepresentable: UIViewControllerRepresentable {
    let viewModel: MessageCenterViewModel

    func makeUIViewController(context: Context) -> ApptentiveNavigationController {
        let editProfile = EditProfileViewController(viewModel: viewModel)
        return ApptentiveNavigationController(rootViewController: editProfile)
    }

    func updateUIViewController(_ uiViewController: ApptentiveNavigationController, context: Context) {}
}
