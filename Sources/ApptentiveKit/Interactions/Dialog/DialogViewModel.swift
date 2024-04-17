//
//  DialogViewModel.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

typealias DialogInteractionDelegate = EventEngaging & InvocationInvoking & ResponseRecording & ResourceProviding

/// Describes the updates to the UI triggered from the view model.
public protocol DialogViewModelDelegate: AnyObject {
    func dialogViewModel(_: DialogViewModel, didLoadImage: DialogViewModel.Image)
    func dismiss()
}

/// Describes the values needed to configure a view for the TextModal ("Note") interaction.
public class DialogViewModel {

    /// The "Do you love this app" question part of the dialog.
    public let title: String?

    /// The "subtitle" of the dialog (which should be blank).
    public let message: String?

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

    /// The maximum percentage (0–100) of the usable vertical screen space that the note should use.
    public var maxHeight: Int = 100

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
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
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

    static let imageScale: CGFloat = 3

    // MARK: - Internal
    let interaction: Interaction
    let interactionDelegate: DialogInteractionDelegate
    let imageConfiguration: TextModalConfiguration.Image?

    init(configuration: TextModalConfiguration, interaction: Interaction, interactionDelegate: DialogInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.dialogType = .textModal
        self.title = configuration.title?.boldHTMLSpan()
        self.message = configuration.body
        self.isMessageHidden = self.message == nil || self.message?.isEmpty == true
        self.isTitleHidden = self.title == nil || self.title?.isEmpty == true

        self.actions = configuration.actions.enumerated().map { (position, action) in
            return Self.buildTextModalAction(action: action, position: position, interaction: interaction, interactionDelegate: interactionDelegate)
        }
        self.imageConfiguration = configuration.image

        if let configurationImage = configuration.image {
            self.dialogContainsImage = true
            let layout = DialogViewModel.Image.Layout(rawValue: configurationImage.layout) ?? .fullWidth
            self.image = .loading(altText: configurationImage.altText, layout: layout)
        } else {
            self.image = .none
        }
    }

    init(configuration: EnjoymentDialogConfiguration, interaction: Interaction, interactionDelegate: DialogInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.dialogType = .enjoymentDialog
        self.title = configuration.title
        self.message = nil
        self.imageConfiguration = nil
        self.image = .none

        self.actions = [
            DialogViewModel.Action(
                label: configuration.noText, actionType: .no,
                buttonTapped: {
                    interactionDelegate.engage(event: .no(from: interaction))
                }),
            DialogViewModel.Action(
                label: configuration.yesText, actionType: .yes,
                buttonTapped: {
                    interactionDelegate.engage(event: .yes(from: interaction))
                }),
        ]
    }

    func prepareForPresentation(completion: @escaping () -> Void) {
        guard let configurationImage = self.imageConfiguration else {
            return completion()
        }

        self.prepareForPresentationCompletion = completion
        self.interactionDelegate.getImage(at: configurationImage.url, scale: Self.imageScale) { result in
            switch result {
            case .success(let image):
                let layout = DialogViewModel.Image.Layout(rawValue: configurationImage.layout) ?? .fullWidth
                self.image = .loaded(image: image, acessibilityLabel: configurationImage.altText, layout: layout, maxHeight: self.maxHeight(with: self.maxHeight))
            case .failure(let error):
                ApptentiveLogger.interaction.error("Error retrieving image from \(configurationImage.url): \(error)")
            }

            self.prepareForPresentationCompletion?()
            self.prepareForPresentationCompletion = nil
        }

        // Display prompt once image loads or after trying for 2 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Self.preloadTimeout)) {
            self.prepareForPresentationCompletion?()
            self.prepareForPresentationCompletion = nil
        }
    }

    // MARK: - Private

    private var prepareForPresentationCompletion: (() -> Void)? = nil
    private static let preloadTimeout = 2

    private func maxHeight(with maxHeight: Int) -> CGFloat {
        let portraitHeight = UIScreen.main.bounds.height
        let safeAreaInsets = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        return (CGFloat(maxHeight) / 100) * (portraitHeight - safeAreaInsets)
    }

    private static func buildTextModalAction(action: TextModalConfiguration.Action, position: Int, interaction: Interaction, interactionDelegate: DialogInteractionDelegate) -> DialogViewModel.Action {
        return DialogViewModel.Action(
            label: action.label,
            actionType: DialogViewModel.Action.ActionType.from(action.actionType),
            buttonTapped: {
                interactionDelegate.recordResponse(.answered([Answer.choice(action.id)]), for: interaction.id)

                switch action.actionType {
                case .dismiss:
                    let invokedAction = TextModalAction(label: action.label, position: position, actionID: action.id)
                    interactionDelegate.engage(event: .dismiss(for: interaction, action: invokedAction))

                case .interaction:
                    guard let invocations = action.invocations else {
                        ApptentiveLogger.engagement.error("TextModal interaction button missing invocations.")
                        return apptentiveCriticalError("TextModal interaction button missing invocations.")
                    }

                    interactionDelegate.invoke(invocations) { (invokedInteractionID) in
                        if let invokedInteractionID = invokedInteractionID {
                            let invokedAction = TextModalAction(label: action.label, position: position, invokedInteractionID: invokedInteractionID, actionID: action.id)
                            interactionDelegate.engage(event: .interaction(for: interaction, action: invokedAction))
                        }
                    }
                }
            })
    }
}

extension Event {

    static func yes(from interaction: Interaction) -> Self {
        return Self.init(internalName: "yes", interaction: interaction)
    }

    static func no(from interaction: Interaction) -> Self {
        return Self.init(internalName: "no", interaction: interaction)
    }

    static func interaction(for interaction: Interaction, action: TextModalAction) -> Self {
        var result = Event(internalName: "interaction", interaction: interaction)

        result.userInfo = .textModalAction(action)

        return result
    }

    static func dismiss(for interaction: Interaction, action: TextModalAction) -> Self {
        var result = Event(internalName: "dismiss", interaction: interaction)

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
