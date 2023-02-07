//
//  DialogViewModel+Action.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/21/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

extension DialogViewModel {
    /// Represents the functionality of the each button in the dialog.
    public class Action {
        /// The text displayed on the button.
        public let label: String
        /// Indicates the type of action the button should trigger when tapped.
        public let actionType: ActionType
        /// Triggers the appropriate outcome depending on the action type.
        public let buttonTapped: () -> Void

        init(label: String, actionType: DialogViewModel.Action.ActionType, buttonTapped: @escaping () -> Void) {
            self.label = label
            self.actionType = actionType
            self.buttonTapped = buttonTapped
        }

        public enum ActionType: String {
            case dismiss
            case interaction
            case yes
            case no

            static func from(_ configurationActionType: TextModalConfiguration.Action.ActionType) -> Self {
                switch configurationActionType {
                case .dismiss:
                    return .dismiss

                case .interaction:
                    return .interaction
                }
            }
        }
    }
}
