//
//  MessageCenterSwiftUIView.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// SwiftUI root view for Message Center. Renders the message list, greeting header,
/// optional status banner and profile input, and docks the compose bar above the keyboard
/// via `safeAreaInset`. Designed to be hosted inside a `UIHostingController` that itself
/// sits in an `ApptentiveNavigationController`, so `.navigationTitle` / `.toolbar` bridge
/// up to that UIKit navigation controller.
struct MessageCenterSwiftUIView: View {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel
    @State private var showEditProfile: Bool = false
    @State private var measuredWidth: CGFloat = 0
    @State private var keyboardActive: Bool = false

    private let bubbleWidthRatio: CGFloat = 0.75

    /// Delay before scrolling the status banner into view on keyboard show. Lets the keyboard
    /// and the bottom safe-area inset finish animating so `scrollTo` resolves against the final
    /// layout instead of the pre-keyboard one (the root cause of the banner landing behind the
    /// keyboard). The keyboard animation is ~0.25s; `keyboardPublisher` is already debounced 0.1s.
    private let keyboardSettleNanoseconds: UInt64 = 200_000_000

    /// Reads public `UIViewController.apptentiveMessageCenterComposerPosition` flag the UIKit UI uses so
    /// both stacks honor the integrator's choice. Inline means the composer renders beneath
    /// the greeting inside the scroll view rather than docked above the keyboard; for `.inline`
    /// the empty (new) dialog is inline, while `.bottom` keeps it docked.
    private var composerIsInline: Bool {
        switch UIViewController.apptentiveMessageCenterComposerPosition {
        case .inline:
            return viewModel.groupedMessages.isEmpty
        case .bottom:
            return false
        }
    }

    var body: some View {
        measuredContent
            .navigationTitle(viewModel.headingTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $viewModel.showImagePicker) {
                PHPickerRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $viewModel.showFilePicker) {
                DocumentPickerRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $viewModel.showPreview) {
                QLPreviewRepresentable(viewModel: viewModel)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showEditProfile, onDismiss: { viewModel.syncProfileFromBase() }) {
                EditProfileRepresentable(viewModel: viewModel.base)
                    .ignoresSafeArea()
            }
            .alert(
                "Attachment error",
                isPresented: Binding(
                    get: { viewModel.attachmentError != nil },
                    set: { if !$0 { viewModel.attachmentError = nil } }
                ),
                presenting: viewModel.attachmentError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
            .alert(
                "",
                isPresented: Binding(
                    get: { viewModel.sendError != nil },
                    set: { if !$0 { viewModel.sendError = nil } }
                ),
                presenting: viewModel.sendError
            ) { _ in
                Button(NSLocalizedString("MC Unavailable Dismiss Button", bundle: .apptentive, value: "OK", comment: "Dismiss button title for note saying MC is unavailable"), role: .cancel) {}
            } message: { _ in
                Text(NSLocalizedString("MC Unavailable Message", bundle: .apptentive, value: "Make sure your device can access the internet and try again.", comment: "Message for note saying MC is unavailable"))
            }
    }

    // MARK: - Width measurement

    /// On iOS 17+ we measure width via `.onGeometryChange` so the scroll/content
    /// participates in standard layout instead of being sized by a root
    /// `GeometryReader` (which fills its proposed size and can interact awkwardly
    /// with safe-area insets). iOS 15/16 doesn't have `onGeometryChange`, so we
    /// keep `GeometryReader` for that fallback.
    @ViewBuilder
    private var measuredContent: some View {
        if #available(iOS 17.0, *) {
            dockedComposer(scrollContainer(maxBubbleWidth: max(measuredWidth * bubbleWidthRatio, 0)))
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { newWidth in
                    if measuredWidth != newWidth {
                        measuredWidth = newWidth
                    }
                }
        } else {
            GeometryReader { proxy in
                dockedComposer(scrollContainer(maxBubbleWidth: max(proxy.size.width * bubbleWidthRatio, 0)))
            }
        }
    }

    // MARK: - Scroll container

    @ViewBuilder
    private func scrollContainer(maxBubbleWidth: CGFloat) -> some View {
        ScrollViewReader { scrollProxy in
            let scrollView = ScrollView {
                VStack(spacing: 0) {
                    GreetingHeaderViewSwiftUI(viewModel: viewModel)

                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.groupedMessages.enumerated()), id: \.element.first?.nonce) { sectionIndex, group in
                            MessageGroupSection(
                                group: group,
                                sectionIndex: sectionIndex,
                                maxBubbleWidth: maxBubbleWidth,
                                viewModel: viewModel
                            )
                        }

                        if let status = viewModel.statusBody {
                            StatusBannerView(text: status)
                                .id("status-banner")
                        }

                        if viewModel.shouldRequestProfile {
                            ProfileInputViewSwiftUI(viewModel: viewModel)
                        }

                        if composerIsInline {
                            ComposeBarViewSwiftUI(viewModel: viewModel)
                                .apptentiveComposeBarBackground()
                        }

                        Color.clear
                            .frame(height: 8)
                            .id("bottom-anchor")
                    }
                }
            }
            .onReceive(keyboardPublisher) { active in
                keyboardActive = active
                guard active else { return }
                // On keyboard show, wait for the inset to settle before scrolling.
                revealStatusAboveKeyboard(scrollProxy, afterSettle: true)
            }
            .onChangeCompat(of: viewModel.statusBody != nil) { hasStatus in
                // The status can appear while the keyboard is already up (e.g. right after
                // sending). Re-run the scroll so it doesn't stay hidden behind the keyboard.
                if hasStatus && keyboardActive {
                    revealStatusAboveKeyboard(scrollProxy, afterSettle: false)
                }
            }

            // `onReceive` (iOS 13+) sidesteps the iOS 17 deprecation of
            // `onChange(of:perform:)` while still working on the iOS 15 floor.
            let withScroll = scrollView.onReceive(viewModel.$scrollTarget) { target in
                guard let target else { return }
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(.easeOut(duration: 0.3)) {
                        scrollProxy.scrollTo(target, anchor: .bottom)
                    }
                    viewModel.scrollTarget = nil
                }
            }

            if #available(iOS 16, *) {
                withScroll.scrollDismissesKeyboard(.interactively)
            } else {
                withScroll
            }
        }
    }

    /// Scrolls the status banner (or the bottom anchor when there is no status) to the bottom
    /// of the visible area so it sits above the keyboard. When `afterSettle` is true, waits for
    /// the keyboard/safe-area inset animation to finish first so the scroll resolves against the
    /// final layout rather than the pre-keyboard one.
    private func revealStatusAboveKeyboard(_ proxy: ScrollViewProxy, afterSettle: Bool) {
        Task { @MainActor in
            if afterSettle {
                try? await Task.sleep(nanoseconds: keyboardSettleNanoseconds)
            } else {
                await Task.yield()
            }
            withAnimation(.easeOut(duration: 0.25)) {
                let target = viewModel.statusBody != nil ? "status-banner" : "bottom-anchor"
                proxy.scrollTo(target, anchor: .bottom)
            }
        }
    }

    // MARK: - Composer placement

    /// Docks the compose bar above the keyboard via `safeAreaInset`. When the composer is
    /// rendered inline (see `composerIsInline`) the scroll content already contains it, so
    /// nothing is added here and the bar scrolls with the content beneath the greeting.
    @ViewBuilder
    private func dockedComposer(_ content: some View) -> some View {
        if composerIsInline {
            content
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                ComposeBarViewSwiftUI(viewModel: viewModel)
                    .apptentiveComposeBarBackground()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                viewModel.cancel()
                viewModel.onRequestDismiss?()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(viewModel.closeButtonAccessibilityLabel)
            .accessibilityHint(viewModel.closeButtonAccessibilityHint)
            .accessibilityIdentifier("closeButton")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.shouldAllowProfileEdit {
                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
                .apptentiveComposeButtonStyle()
                .tint(Color.apptentiveTint)
                .accessibilityLabel(viewModel.profileButtonAccessibilityLabel)
                .accessibilityHint(viewModel.profileButtonAccessibilityHint)
                .accessibilityIdentifier("profileButton")
            }
        }
    }
}
