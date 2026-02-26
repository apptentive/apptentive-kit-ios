//
//  SurveyViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor class SurveyViewModelTests: SurveyViewModelDelegate {
    var viewModel: SurveyViewModel
    var spyInteractionDelegate: SpyInteractionDelegate

    var gotDidFinish: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false
    var gotPageWillChange: Bool = false
    var gotPageDidChange: Bool = false

    init() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "Survey")

        guard case let Interaction.InteractionConfiguration.surveyV12(surveyConfiguration) = interaction.configuration else {
            throw TestError(reason: "Unable to create view model")
        }

        self.spyInteractionDelegate = SpyInteractionDelegate()
        self.viewModel = SurveyViewModel(configuration: surveyConfiguration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate)
        self.viewModel.delegate = self
    }

    @Test func testSurveyMetadata() async throws {
        #expect(self.viewModel.name == "Every Question Type")
        #expect(self.viewModel.advanceButtonText == "Boom")
        #expect(self.viewModel.interaction.id == "1")
        #expect(String(self.viewModel.validationErrorMessage.characters) == "You done goofed.")
        #expect(self.viewModel.introduction.flatMap { String($0.characters) } == "Please help us see how each question is formatted when returning a survey response to the server.")
        #expect(self.viewModel.thankYouMessage.flatMap { String($0.characters) } == "Thank you!")
        #expect(self.viewModel.isRequired == false)
        #expect(self.viewModel.questions.count == 16)
        #expect(viewModel.termsAndConditions?.linkLabel == "Terms & Conditions")

        self.viewModel.openTermsAndConditions()
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
        #expect(self.spyInteractionDelegate.openedURL == URL(string: "https://www.example.com/"))
    }

    @Test func testSurveyQuestionBasics() {
        #expect(String(self.viewModel.questions[0].text.characters) == "Multichoice Optional")
        #expect(self.viewModel.questions[0].instructions == "select one")
    }

    @Test func testOtherOptionSelection() throws {
        let otherQuestion = try #require(viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion)

        #expect(otherQuestion.choices.filter { $0.isSelected }.count == 0)
        otherQuestion.toggleChoice(at: 2)
        #expect(otherQuestion.choices[2].isSelected)
    }

    @Test func testRadioButtonSelection() throws {
        let multichoiceOptional = try #require(viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion)

        #expect(multichoiceOptional.choices.filter { $0.isSelected }.count == 0)
        multichoiceOptional.toggleChoice(at: 0)
        #expect(multichoiceOptional.choices[0].isSelected)
        multichoiceOptional.toggleChoice(at: 1)
        #expect(self.gotSelectionDidChange)
        #expect(multichoiceOptional.choices[1].isSelected)
        #expect(!multichoiceOptional.choices[0].isSelected)
        multichoiceOptional.toggleChoice(at: 1)
        #expect(multichoiceOptional.choices[1].isSelected)
    }

    @Test func testRadioButtonValidation() throws {
        let multichoiceOptional = try #require(viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion)
        let multichoiceRequired = try #require(viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion)

        #expect(multichoiceOptional.isValid)
        multichoiceOptional.toggleChoice(at: 0)
        #expect(multichoiceOptional.isValid)

        #expect(!multichoiceRequired.isValid)
        multichoiceRequired.toggleChoice(at: 0)
        #expect(multichoiceRequired.isValid)
        multichoiceRequired.toggleChoice(at: 0)
        #expect(multichoiceRequired.isValid)
    }

    @Test func testCheckboxSelection() throws {
        let question = try #require(viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion)

        #expect(question.choices.filter { $0.isSelected }.count == 0)

        question.toggleChoice(at: 0)
        #expect(self.gotSelectionDidChange)
        #expect(question.choices[0].isSelected)

        self.gotSelectionDidChange = false

        question.toggleChoice(at: 1)
        #expect(self.gotSelectionDidChange)
        #expect(question.choices[0].isSelected)
        #expect(question.choices[1].isSelected)

        self.gotSelectionDidChange = false

        question.toggleChoice(at: 1)
        #expect(self.gotSelectionDidChange)
        #expect(!question.choices[1].isSelected)
    }

    @Test func testCheckboxValidation() throws {
        let multiselectOptional = try #require(viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequired = try #require(viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion)
        let multiselectOptionalWithLimits = try #require(viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequiredWithLimits = try #require(viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion)

        #expect(multiselectOptional.isValid)
        multiselectOptional.toggleChoice(at: 0)
        #expect(multiselectOptional.isValid)

        #expect(!multiselectRequired.isValid)
        multiselectRequired.toggleChoice(at: 0)
        #expect(!multiselectRequired.isValid, "Other text should be required.")
        multiselectRequired.choices[0].value = "Bar"
        #expect(multiselectRequired.isValid, "Implicit minimum of one selection (provided by server)")

        #expect(multiselectOptionalWithLimits.isValid, "Multiselect optional limits only enforced if something is selected")
        multiselectOptionalWithLimits.toggleChoice(at: 0)
        #expect(!multiselectOptionalWithLimits.isValid, "Multiselect optional lower limit enforced when something is selected")
        multiselectOptionalWithLimits.toggleChoice(at: 1)
        #expect(multiselectOptionalWithLimits.isValid)
        multiselectOptionalWithLimits.toggleChoice(at: 2)
        #expect(!multiselectOptionalWithLimits.isValid, "Multiselect optional other choice should enforce non-null value")
        multiselectOptionalWithLimits.choices[2].value = "Test"
        #expect(multiselectOptionalWithLimits.isValid)
        multiselectOptionalWithLimits.toggleChoice(at: 3)
        #expect(!multiselectOptionalWithLimits.isValid, "Multiselect optional upper limit enforced when something is selected")

        #expect(!multiselectRequiredWithLimits.isValid, "Multiselect required limits enforced even when nothing is selected")
        multiselectRequiredWithLimits.toggleChoice(at: 0)
        #expect(multiselectRequiredWithLimits.isValid)
        multiselectRequiredWithLimits.toggleChoice(at: 1)
        multiselectRequiredWithLimits.toggleChoice(at: 2)
        multiselectRequiredWithLimits.toggleChoice(at: 3)
        #expect(!multiselectRequiredWithLimits.isValid)
    }

    @Test func testFreeformValidation() throws {
        let freeformShortOptional = try #require(viewModel.questions[6] as? SurveyViewModel.FreeformQuestion)
        let freeformShortRequired = try #require(viewModel.questions[7] as? SurveyViewModel.FreeformQuestion)
        let freeformLongOptional = try #require(viewModel.questions[8] as? SurveyViewModel.FreeformQuestion)
        let freeformLongRequired = try #require(viewModel.questions[9] as? SurveyViewModel.FreeformQuestion)

        #expect(freeformShortOptional.isValid)
        #expect(!freeformShortRequired.isValid)
        #expect(freeformLongOptional.isValid)
        #expect(!freeformLongRequired.isValid)

        freeformShortRequired.value = " "
        #expect(!freeformShortRequired.isValid)
        freeformShortRequired.value = "Yo"
        #expect(freeformShortRequired.isValid)

        freeformLongRequired.value = "Hey"
        #expect(freeformLongRequired.isValid)
    }

    @Test func testRangeSelection() throws {
        let rangeNPS = try #require(viewModel.questions[10] as? SurveyViewModel.RangeQuestion)

        #expect(rangeNPS.selectedValueIndex == nil)
        rangeNPS.selectValue(at: 0)
        #expect(rangeNPS.selectedValueIndex == 0)
        rangeNPS.selectValue(at: 1)
        #expect(self.gotSelectionDidChange)
        #expect(rangeNPS.selectedValueIndex == 1)
        rangeNPS.selectValue(at: 1)
        #expect(rangeNPS.selectedValueIndex == 1)

    }

    @Test func testRangeValidation() throws {
        let rangeNPS = try #require(viewModel.questions[10] as? SurveyViewModel.RangeQuestion)
        let rangeHowDoYouFeel = try #require(viewModel.questions[11] as? SurveyViewModel.RangeQuestion)

        #expect(rangeNPS.isValid)
        rangeNPS.selectValue(at: 0)
        #expect(rangeNPS.isValid)

        #expect(!rangeHowDoYouFeel.isValid)
        rangeHowDoYouFeel.selectValue(at: 0)
        #expect(rangeHowDoYouFeel.isValid)
        rangeHowDoYouFeel.selectValue(at: 0)
        #expect(rangeHowDoYouFeel.isValid)
    }

    @Test func testMarkedAsInvalid() async throws {
        let multichoiceOptional = try #require(viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion)
        let multichoiceRequired = try #require(viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion)
        let multiselectOptional = try #require(viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequired = try #require(viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion)
        let multiselectOptionalWithLimits = try #require(viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequiredWithLimits = try #require(viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion)
        let freeformShortOptional = try #require(viewModel.questions[6] as? SurveyViewModel.FreeformQuestion)
        let freeformShortRequired = try #require(viewModel.questions[7] as? SurveyViewModel.FreeformQuestion)
        let freeformLongOptional = try #require(viewModel.questions[8] as? SurveyViewModel.FreeformQuestion)
        let freeformLongRequired = try #require(viewModel.questions[9] as? SurveyViewModel.FreeformQuestion)
        let rangeNPS = try #require(viewModel.questions[10] as? SurveyViewModel.RangeQuestion)
        let rangeHowDoYouFeel = try #require(viewModel.questions[11] as? SurveyViewModel.RangeQuestion)
        let rangeHowCloseToZero = try #require(viewModel.questions[12] as? SurveyViewModel.RangeQuestion)
        let rangeMissingLabels = try #require(viewModel.questions[13] as? SurveyViewModel.RangeQuestion)
        let rangeEmptyLabels = try #require(viewModel.questions[14] as? SurveyViewModel.RangeQuestion)
        let rangeMissingMinMax = try #require(viewModel.questions[15] as? SurveyViewModel.RangeQuestion)

        #expect(!multichoiceOptional.isMarkedAsInvalid)
        #expect(!multichoiceRequired.isMarkedAsInvalid)
        #expect(!multiselectOptional.isMarkedAsInvalid)
        #expect(!multiselectRequired.isMarkedAsInvalid)
        #expect(!multiselectOptionalWithLimits.isMarkedAsInvalid)
        #expect(!multiselectRequiredWithLimits.isMarkedAsInvalid)
        #expect(!freeformShortOptional.isMarkedAsInvalid)
        #expect(!freeformShortRequired.isMarkedAsInvalid)
        #expect(!freeformLongOptional.isMarkedAsInvalid)
        #expect(!freeformLongRequired.isMarkedAsInvalid)
        #expect(!rangeNPS.isMarkedAsInvalid)
        #expect(!rangeHowDoYouFeel.isMarkedAsInvalid)
        #expect(!rangeHowCloseToZero.isMarkedAsInvalid)
        #expect(!rangeMissingLabels.isMarkedAsInvalid)
        #expect(!rangeEmptyLabels.isMarkedAsInvalid)
        #expect(!rangeMissingMinMax.isMarkedAsInvalid)

        // Force "sticky" validation
        await viewModel.advance()
        #expect(!self.gotDidFinish)

        #expect(!multichoiceOptional.isMarkedAsInvalid)
        #expect(!multiselectOptional.isMarkedAsInvalid)
        #expect(!multiselectOptionalWithLimits.isMarkedAsInvalid)
        #expect(!freeformShortOptional.isMarkedAsInvalid)
        #expect(!freeformLongOptional.isMarkedAsInvalid)
        #expect(!rangeNPS.isMarkedAsInvalid)
        #expect(!rangeHowCloseToZero.isMarkedAsInvalid)
        #expect(!rangeMissingLabels.isMarkedAsInvalid)
        #expect(!rangeEmptyLabels.isMarkedAsInvalid)
        #expect(!rangeMissingMinMax.isMarkedAsInvalid)

        #expect(multichoiceRequired.isMarkedAsInvalid)
        #expect(multiselectRequired.isMarkedAsInvalid)
        #expect(multiselectRequiredWithLimits.isMarkedAsInvalid)
        #expect(freeformShortRequired.isMarkedAsInvalid)
        #expect(freeformLongRequired.isMarkedAsInvalid)
        #expect(rangeHowDoYouFeel.isMarkedAsInvalid)

        self.gotValidationDidChange = false
        multichoiceRequired.toggleChoice(at: 0)
        #expect(self.gotValidationDidChange)
        #expect(!multichoiceRequired.isMarkedAsInvalid)

        self.gotValidationDidChange = false
        multiselectRequired.toggleChoice(at: 0)
        multiselectRequired.choices[0].value = "Foo"
        #expect(self.gotValidationDidChange)
        #expect(!multiselectRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        multiselectRequired.toggleChoice(at: 0)
        #expect(!self.gotValidationDidChange)
        #expect(!multiselectRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        multiselectRequiredWithLimits.toggleChoice(at: 0)
        #expect(self.gotValidationDidChange)
        #expect(!multiselectRequiredWithLimits.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        multiselectRequiredWithLimits.toggleChoice(at: 1)
        multiselectRequiredWithLimits.toggleChoice(at: 2)
        multiselectRequiredWithLimits.toggleChoice(at: 3)
        #expect(!self.gotValidationDidChange)
        #expect(!multiselectRequiredWithLimits.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        freeformShortRequired.value = "Yo"
        #expect(self.gotValidationDidChange)
        #expect(!freeformShortRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        freeformShortRequired.value = " "
        #expect(!self.gotValidationDidChange)
        #expect(!freeformShortRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        freeformLongRequired.value = "Hey"
        #expect(self.gotValidationDidChange)
        #expect(!freeformLongRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        freeformLongRequired.value = ""
        #expect(!self.gotValidationDidChange)
        #expect(!freeformLongRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        rangeHowDoYouFeel.selectValue(at: 4)
        #expect(self.gotValidationDidChange)
        #expect(!rangeHowDoYouFeel.isMarkedAsInvalid)
    }

    @Test func testSurveyAnswers() async throws {
        let multichoiceOptional = try #require(viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion)
        let multichoiceRequired = try #require(viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion)
        let multiselectOptional = try #require(viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequired = try #require(viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion)
        let multiselectOptionalWithLimits = try #require(viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion)
        let multiselectRequiredWithLimits = try #require(viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion)
        let freeformShortOptional = try #require(viewModel.questions[6] as? SurveyViewModel.FreeformQuestion)
        let freeformShortRequired = try #require(viewModel.questions[7] as? SurveyViewModel.FreeformQuestion)
        let freeformLongOptional = try #require(viewModel.questions[8] as? SurveyViewModel.FreeformQuestion)
        let freeformLongRequired = try #require(viewModel.questions[9] as? SurveyViewModel.FreeformQuestion)
        let rangeNPS = try #require(viewModel.questions[10] as? SurveyViewModel.RangeQuestion)
        let rangeHowDoYouFeel = try #require(viewModel.questions[11] as? SurveyViewModel.RangeQuestion)
        let rangeHowCloseToZero = try #require(viewModel.questions[12] as? SurveyViewModel.RangeQuestion)
        let rangeMissingLabels = try #require(viewModel.questions[13] as? SurveyViewModel.RangeQuestion)
        let rangeEmptyLabels = try #require(viewModel.questions[14] as? SurveyViewModel.RangeQuestion)
        let rangeMissingMinMax = try #require(viewModel.questions[15] as? SurveyViewModel.RangeQuestion)

        #expect(viewModel.response.questionResponses.values.allSatisfy({ $0 == .empty }))

        multichoiceOptional.toggleChoice(at: 0)
        multichoiceRequired.toggleChoice(at: 1)

        multiselectOptional.toggleChoice(at: 0)
        multiselectOptional.toggleChoice(at: 2)
        multiselectRequired.toggleChoice(at: 0)
        multiselectRequired.choices[0].value = "Bar"
        multiselectOptionalWithLimits.toggleChoice(at: 0)
        multiselectOptionalWithLimits.toggleChoice(at: 1)
        multiselectRequiredWithLimits.toggleChoice(at: 0)
        multiselectRequiredWithLimits.toggleChoice(at: 2)
        multiselectRequiredWithLimits.choices[2].value = "Foo"

        freeformShortOptional.value = " "
        freeformShortRequired.value = "Foo"
        freeformLongOptional.value = "\n"
        freeformLongRequired.value = "Bar"

        rangeNPS.selectValue(at: 10)
        rangeHowDoYouFeel.selectValue(at: 1)
        rangeHowCloseToZero.selectValue(at: 2)
        rangeMissingLabels.selectValue(at: 3)
        rangeEmptyLabels.selectValue(at: 4)
        rangeMissingMinMax.selectValue(at: 5)

        await viewModel.advance()

        #expect(self.gotDidFinish)

        #expect(
            self.spyInteractionDelegate.sentSurveyResponse?.questionResponses == [
                "56e0b5d9c7199274f700001a": .empty,
                "56e0b5d9c7199274f700001c": .empty,
                "2": .answered([Answer.choice("3")]),
                "6": .answered([Answer.choice("8")]),
                "11": .answered([Answer.choice("12"), Answer.choice("14")]),
                "15": .answered([Answer.other("16", "Bar")]),
                "18": .answered([Answer.choice("19"), Answer.choice("20")]),
                "25": .answered([Answer.choice("26"), Answer.other("28", "Foo")]),
                "56e0b5d9c7199274f700001b": .answered([Answer.freeform("Foo")]),
                "56e0b5d9c7199274f700001d": .answered([Answer.freeform("Bar")]),
                "R1": .answered([Answer.range(10)]),
                "R2": .answered([Answer.range(2)]),
                "R3": .answered([Answer.range(-3)]),
                "R4": .answered([Answer.range(4)]),
                "R5": .answered([Answer.range(5)]),
                "R6": .answered([Answer.range(5)]),
            ])
        #expect(self.spyInteractionDelegate.engagedEvent?.codePointName == "com.apptentive#Survey#submit")
        #expect(
            self.spyInteractionDelegate.responses == [
                "2": [Answer.choice("3")],
                "6": [Answer.choice("8")],
                "11": [Answer.choice("12"), Answer.choice("14")],
                "15": [Answer.other("16", "Bar")],
                "18": [Answer.choice("19"), Answer.choice("20")],
                "25": [Answer.choice("26"), Answer.other("28", "Foo")],
                "56e0b5d9c7199274f700001b": [Answer.freeform("Foo")],
                "56e0b5d9c7199274f700001d": [Answer.freeform("Bar")],
                "R1": [Answer.range(10)],
                "R2": [Answer.range(2)],
                "R3": [Answer.range(-3)],
                "R4": [Answer.range(4)],
                "R5": [Answer.range(5)],
                "R6": [Answer.range(5)],
            ])

        #expect(
            self.spyInteractionDelegate.lastResponse == [
                "2": [Answer.choice("3")],
                "6": [Answer.choice("8")],
                "11": [Answer.choice("12"), Answer.choice("14")],
                "15": [Answer.other("16", "Bar")],
                "18": [Answer.choice("19"), Answer.choice("20")],
                "25": [Answer.choice("26"), Answer.other("28", "Foo")],
                "56e0b5d9c7199274f700001b": [Answer.freeform("Foo")],
                "56e0b5d9c7199274f700001d": [Answer.freeform("Bar")],
                "R1": [Answer.range(10)],
                "R2": [Answer.range(2)],
                "R3": [Answer.range(-3)],
                "R4": [Answer.range(4)],
                "R5": [Answer.range(5)],
                "R6": [Answer.range(5)],
            ])

        self.viewModel.launch()

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        #expect(self.spyInteractionDelegate.lastResponse == [:])
    }

    @Test func testBranchedSurvey() async throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranched")

        guard case let Interaction.InteractionConfiguration.surveyV12(surveyConfiguration) = interaction.configuration else {
            throw TestError(reason: "Unable to create view model")
        }

        self.viewModel = SurveyViewModel(configuration: surveyConfiguration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate)
        self.viewModel.delegate = self

        self.viewModel.launch()

        #expect(self.viewModel.currentPage.description.flatMap { String($0.characters) } == "Please tell us about your experience with our survey builder.")

        await self.viewModel.advance()

        #expect(self.viewModel.currentPage.description == nil)

        let firstQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion)

        #expect(String(firstQuestion.text.characters) == "Do you love our current survey building and management experience?")

        firstQuestion.toggleChoice(at: 0)

        await self.viewModel.advance()

        #expect(self.viewModel.currentPage.description == nil)

        let secondQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion)

        #expect(String(secondQuestion.text.characters) == "Happy to hear! What do you love most about our survey experience?")

        await self.viewModel.advance()

        #expect(self.viewModel.currentPage.description == nil)

        let thirdQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion)

        #expect(String(thirdQuestion.text.characters) == "Which two survey features are the most important to you?")

        thirdQuestion.toggleChoice(at: 0)

        await self.viewModel.advance()

        #expect(self.viewModel.currentPage.description == nil)

        let fourthQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion)

        #expect(String(fourthQuestion.text.characters) == "We are testing our new Survey Logic capabilities in this survey! Did you love this new survey experience?")

        fourthQuestion.toggleChoice(at: 1)
        self.spyInteractionDelegate.matchingAdvanceLogicIndex = 1

        await self.viewModel.advance()

        self.spyInteractionDelegate.matchingAdvanceLogicIndex = 0

        #expect(self.viewModel.currentPage.description == nil)

        let fifthQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.FreeformQuestion)

        #expect(String(fifthQuestion.text.characters) == "What would you improve in this new survey experience with logic?")

        await self.viewModel.advance()

        let lastQuestion = try #require(self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion)

        #expect(String(lastQuestion.text.characters) == "Can we contact you for additional feedback or testing to help us improve our Survey Logic features?")

        lastQuestion.toggleChoice(at: 1)

        await self.viewModel.advance()

        #expect(self.viewModel.currentPage.description.flatMap { String($0.characters) } == "Thank you for your valuable time. Your feedback will be used to help us improve our features for you!")

        let response = try #require(self.spyInteractionDelegate.sentSurveyResponse)

        #expect(
            response.questionResponses == [
                "question_1": .answered([.choice("question_1_answer_1")]),
                "question_2": .empty,
                "question_3": .skipped,
                "question_4": .answered([.choice("question_3_answer_1")]),
                "question_5": .answered([.choice("question_5_answer_2")]),
                "question_6": .skipped,
                "question_7": .empty,
                "question_8": .answered([.choice("question_8_answer_2")]),
            ])

        #expect(self.viewModel.advanceButtonText == "Done")

        await self.viewModel.advance()

        #expect(self.gotDidFinish)
    }

    func surveyViewModelDidFinish(_ viewModel: SurveyViewModel) {
        self.gotDidFinish = true
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.gotValidationDidChange = true
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        self.gotSelectionDidChange = true
    }

    func surveyViewModelPageWillChange(_ viewModel: SurveyViewModel) {
        self.gotPageWillChange = true
    }

    func surveyViewModelPageDidChange(_ viewModel: SurveyViewModel) {
        self.gotPageDidChange = true
    }
}
