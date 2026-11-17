//
//  SurveyView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 4/10/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import SwiftUI

struct SurveyView: View {
    @ObservedObject var viewModel: SurveyViewModel
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    // Recomputed only on page transitions (see the onChange below), rather than on every
    // published change from viewModel, since the parent's own objectWillChange re-runs this
    // body far more often than the question list itself actually changes.
    @State private var questionAdapters: [QuestionAdapter] = []

    var body: some View {
        // Page transitions slide only the question list: the ZStack stays put while the list
        // inside is swapped (via `.id`), so the bottom inset (advance button and page
        // indicator) and the toolbar stay static, as in the old UIKit survey.
        ZStack {
            questionList
                .id(viewModel.pageTransitionID)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
        .onChange(of: viewModel.pageTransitionID) { _ in
            questionAdapters = viewModel.questionAdapters
        }
        .onAppear {
            questionAdapters = viewModel.questionAdapters
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isPaged {
                VStack(spacing: 4) {
                    SubmitButtonView(viewModel: viewModel)

                    // Sits between the advance button and the terms & conditions toolbar,
                    // matching the old UIKit survey's bottom view.
                    if viewModel.pageIndicatorSegmentCount > 0 {
                        PageIndicator(segmentCount: viewModel.pageIndicatorSegmentCount, page: viewModel.currentSelectedSegmentIndex)
                            .frame(height: 6)
                            .padding(.vertical, 10)
                            .opacity(viewModel.isSuccessPage ? 0 : 1)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isSuccessPage)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                if let termsLabel = viewModel.termsAndConditions?.linkLabel {
                    // `.bottomBar` items otherwise only get as much width as their ideal/hugging
                    // size (unlike the old UIKit toolbar, which sandwiched the button between two
                    // flexible spaces) — claiming the full width here is what gives `sizeThatFits`
                    // below a real, non-zero width to wrap against.
                    TermsAndConditionsButton(title: termsLabel) {
                        viewModel.openTermsAndConditions()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle(viewModel.name.map(Text.init) ?? Text("SurveyDefaultTitle", bundle: .apptentive, comment: "Default navigation title shown for a survey that has no configured name."))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var questionList: some View {
        List {
            if isPagedDescriptionPage {
                if viewModel.introduction != nil || viewModel.disclaimerText != nil {
                    Section {
                    } header: {
                        pagedDescriptionHeader
                    }
                }
            } else if let introduction = viewModel.introduction {
                Section {
                } header: {
                    AccessibleAttributedText(introduction, uiFont: .apptentiveSurveyIntroductionLabel, textStyle: .subheadline, foregroundColor: .apptentiveSurveyIntroduction, textAlignment: .center)
                        .frame(maxWidth: .infinity)
                        .textCase(nil)
                }
            }

            ForEach(Array(questionAdapters.enumerated()), id: \.element.id) { index, question in
                switch question {
                case .freeform(let q):
                    FreeformQuestionSection(question: q)

                case .choice(let q):
                    ChoiceQuestionSection(question: q, questionIndex: index, viewModel: viewModel)

                case .range(let q):
                    RangeQuestionSection(question: q)
                }
            }

            if !viewModel.isPaged {
                Section {
                    SubmitButtonView(viewModel: viewModel)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }

            if !isPagedDescriptionPage, let disclaimer = viewModel.disclaimerText {
                Section {
                    AccessibleAttributedText(disclaimer, uiFont: .apptentiveDisclaimerLabel, textStyle: .callout, foregroundColor: .apptentiveDisclaimerLabel, textAlignment: .center)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.insetGrouped)
        .modifier(ScrollDismissesKeyboardModifier())
    }

    /// The intro and success pages of a paged survey, which show only a description (introduction
    /// or thank you message) and the disclaimer.
    private var isPagedDescriptionPage: Bool {
        viewModel.isPaged && (viewModel.isIntroPage || viewModel.isSuccessPage)
    }

    private var pagedDescriptionHeader: some View {
        let font: UIFont = viewModel.isIntroPage ? .apptentiveSurveyIntroductionLabel : .apptentiveSubmitStatusLabel
        let textStyle: UIFont.TextStyle = viewModel.isIntroPage ? .subheadline : .headline

        return VStack(spacing: 0) {
            if let introduction = viewModel.introduction {
                AccessibleAttributedText(introduction, uiFont: font, textStyle: textStyle, foregroundColor: .apptentiveSurveyIntroduction, textAlignment: .center)
            }
            if let disclaimer = viewModel.disclaimerText {
                AccessibleAttributedText(disclaimer, uiFont: font, textStyle: textStyle, foregroundColor: .apptentiveDisclaimerLabel, textAlignment: .center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, verticalSizeClass == .compact ? 30 : 128)
        .textCase(nil)
    }
}

// A real UIButton wrapped for SwiftUI, not a SwiftUI `Button`/`Text`: content placed directly
// inside a `ToolbarItem(placement: .bottomBar)` isn't given a bounded width to size against (so a
// long label just runs off screen) and — separately — wasn't reachable by VoiceOver in testing.
// `SurveyHostingController` still needs to own showing/hiding the underlying UIToolbar
// (`setToolbarHidden`), since a plain UIViewRepresentable here doesn't drive that on its own; but
// the toolbar *items* themselves must keep coming from this SwiftUI `.toolbar` modifier rather
// than being set directly via UIKit's `toolbarItems`, because `SurveyView` also uses
// `.navigationTitle`, which makes `UIHostingController` own bar-item reconciliation — it
// re-syncs (and silently clears) `toolbarItems` on every SwiftUI re-render if they weren't set
// through this modifier. A long label is truncated with an ellipsis (one line) rather than
// wrapped, so it can't push the submit button off screen; sizing follows the same `sizeThatFits`
// hook as `AccessibleAttributedText`.
private struct TermsAndConditionsButton: UIViewRepresentable {
    let title: String
    let action: () -> Void

    func makeUIView(context: Context) -> UIButton {
        let button = UIButton()
        // Belt-and-suspenders with the transformer below: hosting a UIButton inside a SwiftUI
        // `ToolbarItem` via `UIViewRepresentable` otherwise left it rendering in the default
        // black/label color instead of the configured tint.
        button.tintColor = .apptentiveTermsOfServiceLabel
        button.configuration = .borderless()
        button.configuration?.baseForegroundColor = .apptentiveTermsOfServiceLabel
        button.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var container = incoming
            container.foregroundColor = .apptentiveTermsOfServiceLabel
            container.font = .apptentiveTermsOfServiceLabel
            container.underlineColor = .apptentiveTermsOfServiceLabel
            container.underlineStyle = [.single]
            return container
        }
        button.configuration?.titleLineBreakMode = .byTruncatingTail
        button.configuration?.titleAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    /// Only claims the toolbar's full width when the label actually needs truncating — otherwise
    /// returns the button's natural (compact) size, which SwiftUI then centers within the wider
    /// slot on its own, matching the old UIKit toolbar button (naturally sized, centered between
    /// two flexible spaces) instead of stretching a short label across the whole screen width.
    @available(iOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView button: UIButton, context: Context) -> CGSize? {
        let naturalSize = button.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))

        // A zero (or unknown) available width means there's nothing meaningful to truncate
        // against yet (e.g. still on the first layout pass), so fall back to the natural size
        // rather than collapsing the wrap/truncation calculation to zero.
        let candidateWidth = proposal.width ?? button.bounds.width
        guard candidateWidth > 0, naturalSize.width > candidateWidth else {
            return naturalSize
        }

        let fitting = button.sizeThatFits(CGSize(width: candidateWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: candidateWidth, height: fitting.height)
    }

    func updateUIView(_ button: UIButton, context: Context) {
        button.configuration?.title = title
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) {
            self.action = action
        }
        @objc func tapped() {
            action()
        }
    }
}

// Wraps the UIKit `SurveyPageIndicatorView` so it keeps its segment/progress-bar styling and
// animations. It lives in the bottom safe-area inset (outside the `.id(pageTransitionID)` list),
// so the same view instance persists across pages and can animate from one page to the next.
private struct PageIndicator: UIViewRepresentable {
    let segmentCount: Int
    let page: Int?

    func makeUIView(context: Context) -> SurveyPageIndicatorView {
        let indicator = SurveyPageIndicatorView(segmentCount: segmentCount)
        // SwiftUI sizes a representable's root view by setting its frame, so it has to keep
        // autoresizing-mask constraints; with them disabled it collapses to zero size.
        indicator.translatesAutoresizingMaskIntoConstraints = true
        return indicator
    }

    func updateUIView(_ indicator: SurveyPageIndicatorView, context: Context) {
        // The intro page has no indicator value, so nothing is highlighted there.
        guard let page, page != context.coordinator.displayedPage else { return }

        indicator.setPage(page, animated: context.coordinator.displayedPage != nil)
        context.coordinator.displayedPage = page
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var displayedPage: Int?
    }
}

/// Restores the old UIKit survey's `keyboardDismissMode = .interactive` (iOS 16+ only; on iOS 15
/// the tap-to-dismiss gesture in `SurveyHostingController` still applies).
private struct ScrollDismissesKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}

private struct FreeformQuestionSection: View {
    @ObservedObject var question: SurveyViewModel.FreeformQuestion

    var body: some View {
        Section {
            FreeformRowView(question: question)
        } header: {
            QuestionHeaderView(question: question)
        } footer: {
            QuestionErrorFooter(question: question)
        }
    }
}

private struct ChoiceQuestionSection: View {
    @ObservedObject var question: SurveyViewModel.ChoiceQuestion
    let questionIndex: Int
    let viewModel: SurveyViewModel

    var body: some View {
        Section {
            ForEach(Array(question.choices.enumerated()), id: \.element.id) { choiceIndex, choice in
                ChoiceRowView(
                    choice: choice,
                    choiceIndex: choiceIndex,
                    questionIndex: questionIndex,
                    selectionStyle: question.selectionStyle,
                    viewModel: viewModel
                )
                .listRowSeparator(choice.supportsOther && choice.isSelected ? .hidden : .automatic, edges: .bottom)
                // Deliberately not folded into a single unary row: the choice row and this
                // field are separate top-level views so their insert/remove gets the List's
                // built-in row animation for free when "Other" is toggled.
                if choice.supportsOther && choice.isSelected {
                    TextField(
                        choice.placeholderText ?? "",
                        text: Binding(
                            get: { choice.value ?? "" },
                            set: { choice.value = $0 }
                        )
                    )
                    .font(.apptentiveTextInput)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground), in: Capsule())
                    .padding(.leading, 32)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 11, trailing: 16))
                }
            }
        } header: {
            QuestionHeaderView(question: question)
        } footer: {
            QuestionErrorFooter(question: question)
        }
    }
}

private struct RangeQuestionSection: View {
    @ObservedObject var question: SurveyViewModel.RangeQuestion

    var body: some View {
        Section {
            RangeRowView(question: question)
        } header: {
            QuestionHeaderView(question: question)
        } footer: {
            QuestionErrorFooter(question: question)
        }
    }
}

private struct QuestionErrorFooter: View {
    @ObservedObject var question: SurveyViewModel.Question

    var body: some View {
        Text(question.errorMessage)
            .foregroundColor(.apptentiveError)
            .opacity(question.isMarkedAsInvalid ? 1 : 0)
            .accessibilityHidden(!question.isMarkedAsInvalid)
    }
}

private struct SubmitButtonView: View {
    @ObservedObject var viewModel: SurveyViewModel

    var body: some View {
        VStack(spacing: 8) {
            Button(viewModel.advanceButtonText) {
                Task { await viewModel.advance() }
            }
            .font(.apptentiveSubmitButtonTitle)
            .buttonStyle(.borderedProminent)
            .tint(.apptentiveTint)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

            if let thankYouMessage = viewModel.thankYouMessage, viewModel.surveyDidSendResponse {
                Text(thankYouMessage)
                    .font(.apptentiveSubmitStatusLabel)
                    .foregroundColor(.apptentiveSubmitStatusLabel)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else if viewModel.isMarkedAsInvalid {
                Text(viewModel.validationErrorMessage)
                    .font(.caption)
                    .foregroundColor(.apptentiveError)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

private struct QuestionHeaderView: View {
    @ObservedObject var question: SurveyViewModel.Question

    var body: some View {
        // Matches the old UIKit header's `UIStackView.spacing` between the question text and the
        // instructions/required hint (`SurveyQuestionHeaderView`), which was 8pt, not 2.
        VStack(alignment: .leading, spacing: 8) {
            // `.headline` (used pre-SwiftUI too — `SurveyQuestionHeaderView.questionLabel.textStyle`)
            // is inherently semibold by default on iOS, which forced every question title bold
            // regardless of actual `<b>` markup in the text. `.body` is the same default point
            // size, just not bold-by-default; `isHeader` (an accessibility trait, not a visual
            // weight) is unaffected, and a custom theme font's own weight still applies as before.
            AccessibleAttributedText(
                question.text,
                uiFont: .apptentiveQuestionLabel,
                textStyle: .body,
                foregroundColor: question.isMarkedAsInvalid ? .apptentiveError : .apptentiveQuestionLabel,
                isHeader: true
            )
            if let instructionsText = combinedInstructions {
                Text(instructionsText)
                    .font(.apptentiveInstructionsLabel)
                    .foregroundColor(question.isMarkedAsInvalid ? .apptentiveError : .apptentiveInstructionsLabel)
            }
        }
        .textCase(nil)
    }

    private var combinedInstructions: String? {
        switch (question.requiredText, question.instructions) {
        case (let required?, let instructions?): return "\(required) - \(instructions)"
        case (let required?, nil): return required
        case (nil, let instructions?): return instructions
        case (nil, nil): return nil
        }
    }
}

private struct FreeformRowView: View {
    @ObservedObject var question: SurveyViewModel.FreeformQuestion

    var body: some View {
        if question.allowMultipleLines {
            TextEditor(
                text: Binding(
                    get: { question.value ?? "" },
                    set: { question.value = $0 }
                )
            )
            .font(.apptentiveTextInput)
            .frame(minHeight: 100)
        } else {
            TextField(
                question.placeholderText ?? "",
                text: Binding(
                    get: { question.value ?? "" },
                    set: { question.value = $0 }
                )
            )
            .font(.apptentiveTextInput)
        }
    }
}

private struct ChoiceRowView: View {
    @ObservedObject var choice: SurveyViewModel.ChoiceQuestion.Choice
    let choiceIndex: Int
    let questionIndex: Int
    let selectionStyle: SurveyViewModel.ChoiceQuestion.SelectionStyle
    let viewModel: SurveyViewModel

    var body: some View {
        Button {
            withAnimation {
                viewModel.toggleChoice(questionIndex: questionIndex, choiceIndex: choiceIndex)
            }
        } label: {
            HStack {
                selectionImage
                    .font(.title2)
                    .foregroundColor(choice.isSelected ? .apptentiveImageSelected : .apptentiveImageNotSelected)
                Text(choice.label)
                    .font(.apptentiveChoiceLabel)
                    .foregroundColor(.apptentiveChoiceLabel)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectionImage: Image {
        switch (selectionStyle, choice.isSelected) {
        case (.checkbox, false): return .apptentiveCheckbox
        case (.checkbox, true): return .apptentiveCheckboxSelected
        case (.radioButton, false): return .apptentiveRadioButton
        case (.radioButton, true): return .apptentiveRadioButtonSelected
        }
    }
}

private struct RangeRowView: View {
    @ObservedObject var question: SurveyViewModel.RangeQuestion

    var body: some View {
        // Matches the old UIKit cell (`SurveyRangeCell`), which put the segmented control first
        // and the min/max labels in a row below it — not above.
        VStack(alignment: .leading, spacing: 8) {
            Picker(
                "",
                selection: Binding(
                    get: { question.selectedValueIndex ?? -1 },
                    set: {
                        if $0 >= 0 {
                            question.selectValue(at: $0)
                        }
                    }
                )
            ) {
                ForEach(Array(question.choiceLabels.enumerated()), id: \.element) { index, label in
                    Text(label).tag(index)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                if let minText = question.minText {
                    Text(minText).font(.apptentiveMinMaxLabel).foregroundColor(.apptentiveMinMaxLabel)
                }
                Spacer()
                if let maxText = question.maxText {
                    Text(maxText).font(.apptentiveMinMaxLabel).foregroundColor(.apptentiveMinMaxLabel)
                }
            }
        }
    }
}

// MARK: - QuestionAdapter

@MainActor
private enum QuestionAdapter {
    case freeform(SurveyViewModel.FreeformQuestion)
    case choice(SurveyViewModel.ChoiceQuestion)
    case range(SurveyViewModel.RangeQuestion)

    /// The underlying question view model, upcast to the shared base class.
    var base: SurveyViewModel.Question {
        switch self {
        case .freeform(let q): return q
        case .choice(let q): return q
        case .range(let q): return q
        }
    }

    var id: String {
        base.questionID
    }
}

extension SurveyViewModel {
    fileprivate var questionAdapters: [QuestionAdapter] {
        questions.map { question in
            if let q = question as? SurveyViewModel.FreeformQuestion {
                return .freeform(q)
            } else if let q = question as? SurveyViewModel.ChoiceQuestion {
                return .choice(q)
            } else if let q = question as? SurveyViewModel.RangeQuestion {
                return .range(q)
            } else {
                fatalError("Unknown question type: \(type(of: question))")
            }
        }
    }

    fileprivate func toggleChoice(questionIndex: Int, choiceIndex: Int) {
        guard let choiceQuestion = questions[questionIndex] as? SurveyViewModel.ChoiceQuestion else { return }
        choiceQuestion.toggleChoice(at: choiceIndex)
    }
}

#if DEBUG

    @MainActor
    private final class PreviewInteractionDelegate: EventEngaging, ResponseSending, ResponseRecording, URLOpening, SurveyBranching {
        func engage(event: Event) {}
        func send(surveyResponse: SurveyResponse) async {}
        func recordResponse(_ response: QuestionResponse, for questionID: String) async {}
        func setCurrentResponse(_ response: QuestionResponse, for questionID: String) async {}
        func resetCurrentResponse(for questionID: String) async {}
        func open(_ url: URL) async -> Bool { false }
        func getNextPageID(for advanceLogic: [AdvanceLogic]) async throws -> String? { nil }
    }

    @MainActor
    private func makePreviewViewModel() -> SurveyViewModel {
        let json = """
            {
                "id": "preview_survey",
                "type": "Survey",
                "configuration": {
                    "title": "Sample Survey",
                    "name": "Customer Feedback",
                    "description": "<p>We'd love to hear your feedback!</p>",
                    "success_message": "<p>Thank you for your feedback!</p>",
                    "show_success_message": true,
                    "validation_error": "<p>Please answer all required questions.</p>",
                    "required_text": "Required",
                    "close_confirm_title": "Close Survey?",
                    "close_confirm_message": "Your responses will be lost.",
                    "close_confirm_close_text": "Close",
                    "close_confirm_back_text": "Continue",
                    "render_as": "list",
                    "question_sets": [
                        {
                            "id": "set_1",
                            "button_text": "Submit",
                            "invokes": [],
                            "questions": [
                                {
                                    "id": "q1",
                                    "value": "<p>How would you rate your experience?</p>",
                                    "type": "range",
                                    "error_message": "Please select a rating",
                                    "required": true,
                                    "min": 1,
                                    "max": 5,
                                    "min_label": "Poor",
                                    "max_label": "Excellent"
                                },
                                {
                                    "id": "q2",
                                    "value": "<p>Would you recommend us to a friend?</p>",
                                    "type": "multichoice",
                                    "error_message": "Please select an option",
                                    "required": true,
                                    "instructions": "select one",
                                    "answer_choices": [
                                        {"id": "c1", "value": "Definitely"},
                                        {"id": "c2", "value": "Probably"},
                                        {"id": "c3", "value": "Not sure"},
                                        {"id": "c4", "value": "Probably not", "type": "select_other", "hint": "Tell us more..."}
                                    ]
                                },
                                {
                                    "id": "q3",
                                    "value": "<p>Any other comments?</p>",
                                    "type": "singleline",
                                    "error_message": "Please provide your feedback",
                                    "required": false,
                                    "freeform_hint": "Type your answer here..."
                                }
                            ]
                        }
                    ]
                }
            }
            """
        guard let data = json.data(using: .utf8),
            let interaction = try? JSONDecoder().decode(Interaction.self, from: data),
            case .surveyV12(let config) = interaction.configuration
        else {
            fatalError("Preview: unexpected interaction configuration type")
        }
        return SurveyViewModel(configuration: config, interaction: interaction, interactionDelegate: PreviewInteractionDelegate(), whereEvent: nil)
    }

    @available(iOS 16.0, *)
    #Preview {
        NavigationStack {
            SurveyView(viewModel: makePreviewViewModel())
        }
    }

#endif
