//
//  MessageCenterSwiftUIViewModel.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/07/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import Combine
import UIKit
import UniformTypeIdentifiers

/// ObservableObject adapter that bridges `MessageCenterViewModel` (UIKit/delegate-based) to SwiftUI.
///
/// Takes ownership of `MessageCenterViewModel.delegate`. Sets `@Published` properties from
/// delegate callbacks so SwiftUI views re-render automatically. Config strings are exposed as
/// computed passthroughs to `base` with no storage duplication.
@MainActor final class MessageCenterSwiftUIViewModel: ObservableObject, MessageCenterViewModelDelegate {

    let base: MessageCenterViewModel

    // MARK: - @Published state

    @Published var groupedMessages: [[MessageCenterViewModel.Message]] = []

    /// Two-way binding: reads from and writes to `base.draftMessageBody`.
    /// The delegate callback guard (`draftMessageBody != incoming`) prevents the
    /// keystroke → base write → delegate callback → re-publish loop.
    @Published var draftMessageBody: String = "" {
        didSet {
            base.draftMessageBody = draftMessageBody.isEmpty ? nil : draftMessageBody
        }
    }

    @Published var draftAttachments: [MessageCenterViewModel.Message.Attachment] = []

    /// Two-way binding for the profile name field. Mirrors `base.name`.
    /// The `profileIsValid` guard prevents a redundant Bool publish on every
    /// keystroke that doesn't actually flip validity.
    @Published var profileName: String = "" {
        didSet {
            base.name = profileName.isEmpty ? nil : profileName
            updateProfileIsValidIfChanged()
        }
    }

    /// Two-way binding for the profile email field. Mirrors `base.emailAddress`.
    @Published var profileEmail: String = "" {
        didSet {
            base.emailAddress = profileEmail.isEmpty ? nil : profileEmail
            updateProfileIsValidIfChanged()
        }
    }

    @Published var profileIsValid: Bool = true
    @Published var shouldRequestProfile: Bool = false
    @Published var shouldAllowProfileEdit: Bool = false
    @Published var hasLoadedMessages: Bool = false
    @Published var greetingImage: UIImage?
    @Published var scrollTarget: String?
    @Published var showImagePicker: Bool = false
    @Published var showFilePicker: Bool = false
    @Published var showPreview: Bool = false
    @Published var previewItems: [MessageCenterViewModel.Message.Attachment] = []
    @Published var attachmentError: Error?
    @Published var sendError: Error?

    /// Injected by `MessageCenterSwiftUIHostingController` so the SwiftUI close button can
    /// trigger UIKit modal dismissal. `@Environment(\.dismiss)` is unreliable when the
    /// SwiftUI view is hosted inside a UIKit `UINavigationController` subclass.
    var onRequestDismiss: (() -> Void)?

    // MARK: - Config strings (computed passthroughs)

    var headingTitle: String { base.headingTitle }
    var greetingTitle: String { base.greetingTitle }
    var greetingBody: String { base.greetingBody }
    var composerPlaceholderText: String { base.composerPlaceholderText }
    var profileNamePlaceholder: String { base.profileNamePlaceholder }
    var profileEmailPlaceholder: String { base.profileEmailPlaceholder }
    var profileEmailInvalidError: String { base.profileEmailInvalidError }
    var profileCancelButtonText: String { base.profileCancelButtonText }
    var profileSaveButtonText: String { base.profileSaveButtonText }
    var editProfileViewTitle: String { base.editProfileViewTitle }
    var editProfileNamePlaceholder: String { base.editProfileNamePlaceholder }
    var editProfileEmailPlaceholder: String { base.editProfileEmailPlaceholder }
    var editProfileCancelButtonText: String { base.editProfileCancelButtonText }
    var editProfileSaveButtonText: String { base.editProfileSaveButtonText }
    var closeButtonAccessibilityLabel: String { base.closeButtonAccessibilityLabel }
    var closeButtonAccessibilityHint: String { base.closeButtonAccessibilityHint }
    var profileButtonAccessibilityLabel: String { base.profileButtonAccessibilityLabel }
    var profileButtonAccessibilityHint: String { base.profileButtonAccessibilityHint }
    var sendButtonAccessibilityLabel: String { base.sendButtonAccessibilityLabel }
    var sendButtonAccessibilityHint: String { base.sendButtonAccessibilityHint }
    var attachButtonAccessibilityLabel: String { base.attachButtonAccessibilityLabel }
    var attachButtonAccessibilityHint: String { base.attachButtonAccessibilityHint }
    var attachmentOptionsTitle: String { base.attachmentOptionsTitle }
    var attachmentOptionsImagesButton: String { base.attachmentOptionsImagesButton }
    var attachmentOptionsFilesButton: String { base.attachmentOptionsFilesButton }
    var attachmentOptionsCancelButton: String { base.attachmentOptionsCancelButton }
    var showAttachmentButtonAccessibilityHint: String { base.showAttachmentButtonAccessibilityHint }
    var downloadAttachmentButtonAccessibilityHint: String { base.downloadAttachmentButtonAccessibilityHint }
    var allUTTypes: [UTType] { base.allUTTypes }
    var remainingAttachmentSlots: Int { base.remainingAttachmentSlots }

    // MARK: - Send / attach gating (computed from @Published state)
    //
    // Computing these instead of caching avoids a UIKit bug where `validateProfile()`
    // updates `base.profileIsValid` silently — without a delegate callback — so a
    // cached `canSendMessage` would not refresh when only the profile fields change.
    // Driving SwiftUI redraws off the underlying @Published properties makes the
    // gating structurally correct: when any dependency changes, the view re-renders
    // and these computed properties return the up-to-date answer.

    var canSendMessage: Bool {
        (draftAttachments.count > 0 || !draftMessageBody.isEmpty) && profileIsValid
    }

    var canAddAttachment: Bool {
        remainingAttachmentSlots > 0
    }

    /// The "we'll respond soon" banner text, shown only right after the user sends a
    /// message — hidden once the newest message is a reply (or there are no messages yet).
    /// `base.statusBody` is just the configured copy with no such gating; mirrors the check
    /// UIKit's `MessageCenterViewController.updateFooter()` does before un-hiding `statusView`.
    var statusBody: String? {
        guard let newestMessageIndexPath = base.newestMessageIndexPath,
            case .sentFromDevice = base.message(at: newestMessageIndexPath).direction
        else {
            return nil
        }
        return base.statusBody
    }

    // MARK: - Init

    init(base: MessageCenterViewModel) {
        self.base = base
        base.delegate = self

        self.profileName = base.name ?? ""
        self.profileEmail = base.emailAddress ?? ""
        self.profileIsValid = base.profileIsValid
        self.shouldRequestProfile = base.shouldRequestProfile

        Task {
            // Downsample once so the displayed 100×100 image isn't held as a
            // full-resolution decoded bitmap.
            let raw = try? await base.getGreetingImage()
            let target = CGSize(width: 100, height: 100)
            greetingImage = raw?.preparingThumbnail(of: target) ?? raw
        }
    }

    // MARK: - Actions (forwarded to base)

    func launch() {
        base.launch()
    }

    func cancel() {
        base.cancel()
    }

    func sendMessage() async throws {
        try await base.commitProfileEdits()
        try await base.sendMessage()
    }

    func addImageAttachment(_ image: UIImage, name: String?) async throws {
        try await base.addImageAttachment(image, name: name)
    }

    func addFileAttachment(at sourceURL: URL) async throws {
        try await base.addFileAttachment(at: sourceURL)
    }

    func removeAttachment(at index: Int) async throws {
        try await base.removeAttachment(at: index)
    }

    func downloadAttachment(at index: Int, inMessageAt indexPath: IndexPath) async throws {
        try await base.downloadAttachment(at: index, inMessageAt: indexPath)
    }

    /// Open an attachment from a tap. Shows the preview if the file is already on disk;
    /// otherwise the tap starts the download, whose completion flows back through
    /// `messageManagerMessagesDidChange` and refreshes the thumbnail — a subsequent tap
    /// then opens the downloaded file. Surfaces any download failure via `attachmentError`
    /// so the host view's `.alert` can render it. Synchronous from the caller's
    /// perspective — the download Task is owned here.
    func openAttachment(at index: Int, in message: MessageCenterViewModel.Message, indexPath: IndexPath) {
        let attachment = message.attachments[index]
        if attachment.localURL != nil {
            previewItems = [attachment]
            showPreview = true
            return
        }
        Task {
            do {
                try await base.downloadAttachment(at: index, inMessageAt: indexPath)
            } catch {
                attachmentError = error
            }
        }
    }

    func commitProfileEdits() async throws {
        try await base.commitProfileEdits()
        syncProfileFromBase()
    }

    /// Call when the inline profile fields lose focus (the user taps away from both
    /// name and email). Mirrors UIKit's `textFieldDidEndEditing`: commits the fields to
    /// the Conversation if valid — so they're not lost on dismiss — then re-syncs
    /// `shouldRequestProfile` from `base`'s real formula (`updateFooter()`'s
    /// `validateProfile()` call in UIKit), rather than forcing the form to hide.
    ///
    /// Triggered on focus loss rather than a typing-pause timer: a debounce fires
    /// whenever the user simply pauses while still typing (e.g. between "gg@mail.co"
    /// and finishing "...com" — ".co" alone is already a format-valid TLD), dismissing
    /// the form mid-edit. Focus loss only fires once the user actually leaves the field.
    func profileFieldsDidLoseFocus() {
        guard base.profileIsValid else { return }
        Task {
            try? await base.commitProfileEdits()
        }
        base.validateProfile()
        if shouldRequestProfile != base.shouldRequestProfile {
            shouldRequestProfile = base.shouldRequestProfile
        }
    }

    func cancelProfileEdits() {
        base.cancelProfileEdits()
        syncProfileFromBase()
    }

    /// Re-syncs `profileName`, `profileEmail`, and `profileIsValid` from `base`.
    /// Call when something outside the bridge has mutated profile state on the base
    /// view model — for example, after dismissing `EditProfileViewController`, which
    /// writes directly to `base` without firing the `draftMessageDidUpdate` delegate.
    func syncProfileFromBase() {
        let baseName = base.name ?? ""
        let baseEmail = base.emailAddress ?? ""
        if profileName != baseName { profileName = baseName }
        if profileEmail != baseEmail { profileEmail = baseEmail }
        updateProfileIsValidIfChanged()
    }

    func markMessageAsRead(at indexPath: IndexPath) {
        base.markMessageAsRead(at: indexPath)
    }

    func getProfilePhoto(for indexPath: IndexPath) async throws -> UIImage? {
        try await base.getProfilePhoto(for: indexPath)
    }

    func dateStringForMessagesInGroup(at index: Int) -> String? {
        base.dateStringForMessagesInGroup(at: index)
    }

    // MARK: - MessageCenterViewModelDelegate

    func messageCenterViewModelDidBeginUpdates(_ viewModel: MessageCenterViewModel) {}

    func messageCenterViewModel(_ viewModel: MessageCenterViewModel, didInsertSectionsWith sectionIndexes: IndexSet) {}

    func messageCenterViewModel(_ viewModel: MessageCenterViewModel, didDeleteSectionsWith sectionIndexes: IndexSet) {}

    func messageCenterViewModel(_ viewModel: MessageCenterViewModel, didDeleteRowsAt indexPaths: [IndexPath]) {}

    func messageCenterViewModel(_ viewModel: MessageCenterViewModel, didUpdateRowsAt indexPaths: [IndexPath]) {}

    func messageCenterViewModel(_ viewModel: MessageCenterViewModel, didInsertRowsAt indexPaths: [IndexPath]) {}

    func messageCenterViewModelDidEndUpdates(_ viewModel: MessageCenterViewModel) {
        snapshotState()
        setScrollTarget()
    }

    func messageCenterViewModelMessageListDidLoad(_ viewModel: MessageCenterViewModel) {
        snapshotState()
        hasLoadedMessages = true
        setScrollTarget()
    }

    func messageCenterViewModelDraftMessageDidUpdate(_ viewModel: MessageCenterViewModel) {
        let incoming = base.draftMessageBody ?? ""
        if draftMessageBody != incoming {
            draftMessageBody = incoming
        }
        if draftAttachments != base.draftAttachments {
            draftAttachments = base.draftAttachments
        }
    }

    // MARK: - Private

    private static func isValidEmail(_ email: String) -> Bool {
        let regex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }

    /// Guarded so unchanged values don't trigger spurious view re-renders.
    /// `groupedMessages` is the expensive one — even if its contents haven't moved,
    /// an unconditional assignment invalidates every visible row.
    private func snapshotState() {
        // `shouldRequestProfile` factors in whether any messages exist yet, so it must be
        // recomputed on every message-list change (e.g. right after sending the first
        // message) — not just on the initial load. `base` only does this itself on initial
        // load; UIKit's MessageCenterViewController compensates by calling validateProfile()
        // from updateFooter() on every update. Mirror that here so the profile prompt
        // actually dismisses once messages exist and the profile is otherwise valid.
        base.validateProfile()

        if groupedMessages != base.groupedMessages {
            groupedMessages = base.groupedMessages
        }
        if shouldRequestProfile != base.shouldRequestProfile {
            shouldRequestProfile = base.shouldRequestProfile
        }
        if shouldAllowProfileEdit != base.shouldAllowProfileEdit {
            shouldAllowProfileEdit = base.shouldAllowProfileEdit
        }
    }

    private func updateProfileIsValidIfChanged() {
        let newValidity = base.profileIsValid
        if profileIsValid != newValidity {
            profileIsValid = newValidity
        }
    }

    private func setScrollTarget() {
        if let unread = base.oldestUnreadMessageIndexPath {
            scrollTarget = "msg-\(unread.section)-\(unread.row)"
        } else {
            // Scroll to the bottom anchor (which sits below the status banner and profile
            // prompt) rather than the newest message bubble, so trailing content stays
            // visible above the keyboard instead of being pushed behind it when a new
            // message is sent. With no trailing content the anchor is ~8pt below the newest
            // bubble, so this matches the previous behavior in the common case.
            scrollTarget = "bottom-anchor"
        }
    }
}
