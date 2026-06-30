//
//  DialogViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

typealias DialogInteractionDelegate = EventEngaging & InvocationInvoking & ResponseRecording & ResourceProviding & EnjoymentRecording & Sendable

/// Describes the updates to the UI triggered from the view model.
@MainActor public protocol DialogViewModelDelegate: AnyObject {
    func dialogViewModel(_: DialogViewModel, didLoadImage: DialogViewModel.Image)
    func dismiss()
}

/// Describes the values needed to configure a view for the TextModal ("Note") interaction.
@MainActor public class DialogViewModel {

    /// The "Do you love this app" question part of the dialog.
    public let title: AttributedString?

    /// The "subtitle" of the dialog (which should be blank).
    public let message: AttributedString?

    /// Indicates if this view model will be used to configure a Love Dialog.
    public let dialogType: DialogType

    /// The data and actions for each button for a note.
    public let actions: [DialogViewModel.Action]

    /// Tells the DialogView how to configure the constraints based on if there is an image.
    public var dialogContainsImage: Bool = false

    /// Indicates if the title is not present to configure the UI.
    var isTitleHidden: Bool = false

    /// Indicates if the message is not present to configure the UI.
    var isMessageHidden: Bool = false

    /// Indicates the properties of the image to be displayed on the note.
    public var image: DialogViewModel.Image {
        didSet {
            self.delegate?.dialogViewModel(self, didLoadImage: self.image)
        }
    }

    /// The vertical position of the dialog.
    public var position: Position

    /// The vertical margin in points between the top/bottom of the safe area and the top/bottom edge of the dialog.
    public var verticalMargins: CGFloat

    /// The delegate used to update the DialogViewController.
    public weak var delegate: DialogViewModelDelegate?

    /// Triggers the action based upon the button that is tapped.
    ///  - Parameter position: The index of the button.
    public func buttonSelected(at position: Int) {
        self.actions[position].buttonTapped()

        self.delegate?.dismiss()
    }

    /// Engages a launch event for the interaction.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction, whereEvent: self.whereEvent))
    }

    /// Engages a cancel event for the interaction (not used by the default implementation).
    public func cancel() {
        self.interactionDelegate.engage(event: .cancel(from: self.interaction))
    }

    /// The type of dialog that the view model represents.
    public enum DialogType {

        /// The dialog type for a Love Dialog (EnjoymentDialog) interaction.
        case enjoymentDialog

        /// The dialog type for a Note (TextModal) interaction.
        case textModal
    }

    /// Describes the on-screen vertical position of the dialog.
    public enum Position: String, Sendable, Codable, RawRepresentable {
        /// The dialog is positioned at the top of the screen.
        case top = "top"

        /// The dialog is positioned in the center of the screen.
        case center = "center"

        /// The dialog is positioned at the bottom of the screen.
        case bottom = "bottom"
    }

    // MARK: - Internal
    let interaction: Interaction
    let interactionDelegate: DialogInteractionDelegate
    let imageConfiguration: TextModalConfiguration.Image?
    let whereEvent: String?

    init(configuration: TextModalConfiguration, interaction: Interaction, interactionDelegate: DialogInteractionDelegate, whereEvent: String?) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.dialogType = .textModal
        self.title = configuration.title
        self.message = configuration.body
        self.isMessageHidden = configuration.body == nil || configuration.body?.characters.isEmpty == true
        self.isTitleHidden = configuration.title == nil || configuration.title?.characters.isEmpty == true
        self.whereEvent = whereEvent

        self.actions = configuration.actions.enumerated().map { (position, action) in
            return Self.buildTextModalAction(action: action, position: position, interaction: interaction, interactionDelegate: interactionDelegate, whereEvent: whereEvent)
        }
        self.imageConfiguration = configuration.image

        if let configurationImage = configuration.image {
            self.dialogContainsImage = true
            let layout = DialogViewModel.Image.Layout(rawValue: configurationImage.layout) ?? .fullWidth
            self.image = .loading(altText: configurationImage.altText, layout: layout)
        } else if let staticImage = UIImage.apptentiveDialogHeader {
            self.dialogContainsImage = true
            self.image = .loaded(image: staticImage, acessibilityLabel: "", layout: .fullWidth)
        } else {
            self.image = .none
        }

        self.position = configuration.position ?? .center
        self.verticalMargins = configuration.verticalMargins ?? 0
    }

    init(configuration: EnjoymentDialogConfiguration, interaction: Interaction, interactionDelegate: DialogInteractionDelegate, whereEvent: String?) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.dialogType = .enjoymentDialog
        self.title = configuration.title
        self.message = nil
        self.imageConfiguration = nil
        if let staticImage = UIImage.apptentiveDialogHeader {
            self.dialogContainsImage = true
            self.image = .loaded(image: staticImage, acessibilityLabel: "", layout: .fullWidth)
        } else {
            self.image = .none
        }
        self.whereEvent = whereEvent

        self.actions = [
            DialogViewModel.Action(
                label: configuration.noText, actionType: .no,
                buttonTapped: {
                    interactionDelegate.recordEnjoyment(false, from: interaction, whereEvent: whereEvent)
                }),
            DialogViewModel.Action(
                label: configuration.yesText, actionType: .yes,
                buttonTapped: {
                    interactionDelegate.recordEnjoyment(true, from: interaction, whereEvent: whereEvent)
                }),
        ]

        self.isMessageHidden = true

        self.position = configuration.position ?? .center
        self.verticalMargins = configuration.verticalMargins ?? 0
    }

    func prepareForPresentation() async {
        guard let configurationImage = self.imageConfiguration else {
            return
        }

        let _: Void = await withCheckedContinuation { continuation in
            Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        // Add a task that tries loading the image.
                        group.addTask {
                            let image = try await self.interactionDelegate.getImage(at: configurationImage.url, scale: Self.imageScale)
                            let layout = DialogViewModel.Image.Layout(rawValue: configurationImage.layout) ?? .fullWidth
                            await self.setImage(.loaded(image: image, acessibilityLabel: configurationImage.altText, layout: layout))
                        }

                        // Also start a timeout task that waits for 2 seconds.
                        group.addTask {
                            try await Task.sleep(nanoseconds: UInt64(Self.preloadTimeout) * NSEC_PER_SEC)
                            Logger.interaction.warning("Image load timed out, presenting dialog anyway.")
                        }

                        // Wait for the image to load or the timer to time out, whichever happens first, and return from this method.
                        let _ = try await group.next()
                        continuation.resume()
                    }
                } catch let error {
                    Logger.interaction.warning("Image load failed with error \(error), presenting dialog anyway.")
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Private

    private var prepareForPresentationCompletion: (() -> Void)? = nil
    private static let preloadTimeout = 2
    private static let imageScale: CGFloat = 3

    private func setImage(_ image: DialogViewModel.Image) {
        self.image = image
    }

    private static func buildTextModalAction(action: TextModalConfiguration.Action, position: Int, interaction: Interaction, interactionDelegate: DialogInteractionDelegate, whereEvent: String?) -> DialogViewModel.Action {
        return DialogViewModel.Action(
            label: action.label,
            actionType: DialogViewModel.Action.ActionType.from(action.actionType),
            buttonTapped: {
                Task {
                    await interactionDelegate.recordResponse(.answered([Answer.choice(action.id)]), for: interaction.id)
                }

                switch action.actionType {
                case .dismiss:
                    let invokedAction = TextModalAction(label: action.label, position: position, actionID: action.id)
                    interactionDelegate.engage(event: .dismiss(for: interaction, action: invokedAction, whereEvent: whereEvent))

                case .interaction:
                    guard let invocations = action.invocations else {
                        Logger.engagement.error("TextModal interaction button missing invocations.")
                        return apptentiveCriticalError("TextModal interaction button missing invocations.")
                    }

                    Task {
                        let invokedInteractionID = try await interactionDelegate.invoke(invocations)
                        let invokedAction = TextModalAction(label: action.label, position: position, invokedInteractionID: invokedInteractionID, actionID: action.id)
                        interactionDelegate.engage(event: .interaction(for: interaction, action: invokedAction, whereEvent: whereEvent))
                    }
                }
            })
    }
}

extension Event {

    static func yes(from interaction: Interaction, whereEvent: String?) -> Self {
        return Self.init(internalName: "yes", interaction: interaction, whereEvent: whereEvent)
    }

    static func no(from interaction: Interaction, whereEvent: String?) -> Self {
        return Self.init(internalName: "no", interaction: interaction, whereEvent: whereEvent)
    }

    static func interaction(for interaction: Interaction, action: TextModalAction, whereEvent: String?) -> Self {
        var result = Event(internalName: "interaction", interaction: interaction, whereEvent: whereEvent)

        result.userInfo = .textModalAction(action)

        return result
    }

    static func dismiss(for interaction: Interaction, action: TextModalAction, whereEvent: String?) -> Self {
        var result = Event(internalName: "dismiss", interaction: interaction, whereEvent: whereEvent)

        result.userInfo = .textModalAction(action)

        return result
    }
}

struct TextModalAction: Codable, Equatable {
    let label: String
    let position: Int
    var invokedInteractionID: String?
    let actionID: String

    enum CodingKeys: String, CodingKey {
        case label
        case position
        case invokedInteractionID = "invoked_interaction_id"
        case actionID = "action_id"
    }
}
