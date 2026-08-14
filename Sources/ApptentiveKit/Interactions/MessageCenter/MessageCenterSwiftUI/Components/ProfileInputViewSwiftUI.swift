//
//  ProfileInputViewSwiftUI.swift
//  ApptentiveKit
//
//  Created by Mikita Halitski on 05/13/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

/// Profile capture fields shown above the compose bar when the configuration requests it.
/// Name and email TextFields with a conditional email-validation error message.
/// On iOS 26+, each field is wrapped in a glass-effect capsule container.
struct ProfileInputViewSwiftUI: View {
    @ObservedObject var viewModel: MessageCenterSwiftUIViewModel

    private enum Field: Hashable {
        case name
        case email
    }

    @FocusState private var focusedField: Field?

    private let cornerRadius: CGFloat = 5
    private let fieldVerticalPadding: CGFloat = 10
    private let fieldHorizontalPadding: CGFloat = 10
    private let fieldMinHeight: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            nameField
            emailField
            if !viewModel.profileIsValid, !viewModel.profileEmail.isEmpty {
                Text(viewModel.profileEmailInvalidError)
                    .font(.apptentiveInstructionsLabel)
                    .foregroundStyle(Color.apptentiveError)
                    .padding(.horizontal, 5)
                    .accessibilityIdentifier("emailError")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onSubmit {
            switch focusedField {
            case .name:
                focusedField = .email
            case .email, .none:
                focusedField = nil
            }
        }
        // Commit only once focus actually leaves both fields (mirrors UIKit's
        // textFieldDidEndEditing) — moving between name and email via `.onSubmit`
        // above isn't "done editing," so this only fires when the new value is nil.
        .onChangeCompat(of: focusedField) { newValue in
            if newValue == nil {
                viewModel.profileFieldsDidLoseFocus()
            }
        }
    }

    private var nameField: some View {
        fieldBackground(isError: false) {
            TextField(viewModel.profileNamePlaceholder, text: $viewModel.profileName)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .accessibilityIdentifier("name")
        }
    }

    private var emailField: some View {
        fieldBackground(isError: !viewModel.profileIsValid && !viewModel.profileEmail.isEmpty) {
            HStack(spacing: 8) {
                emailTextField
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .email)
                    .accessibilityIdentifier("email")

                if !viewModel.profileIsValid && !viewModel.profileEmail.isEmpty {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundStyle(Color.apptentiveError)
                        .imageScale(.medium)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    @ViewBuilder
    private var emailTextField: some View {
        let field = TextField(viewModel.profileEmailPlaceholder, text: $viewModel.profileEmail)
        if #available(iOS 16.0, *) {
            field.autocorrectionDisabled(true)
        } else {
            field.disableAutocorrection(true)
        }
    }

    private func fieldBackground<Content: View>(isError: Bool, @ViewBuilder content: () -> Content) -> some View {
        // Reuse the compose-bar cap so name/email fields don't balloon to
        // screen-dominating heights at accessibility text sizes.
        content()
            .font(Font(ComposeTextInputRepresentable.cappedFont()))
            .foregroundStyle(Color.apptentiveMessageCenterTextInput)
            .padding(.horizontal, fieldHorizontalPadding)
            .padding(.vertical, fieldVerticalPadding)
            .frame(minHeight: fieldMinHeight)
            .apptentiveInputBackground(
                fill: .apptentiveTextInputBackground,
                stroke: isError ? .apptentiveError : .apptentiveMessageCenterTextInputBorder,
                cornerRadius: cornerRadius
            )
    }
}
