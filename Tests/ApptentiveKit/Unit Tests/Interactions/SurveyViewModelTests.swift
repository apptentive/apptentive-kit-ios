//
//  SurveyViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/27/20.
//  Copyright © 2020 Apptentive. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SurveyViewModelTests: XCTestCase, SurveyViewModelDelegate {
    var viewModel: SurveyViewModel!
    var spyInteractionDelegate: SpyInteractionDelegate!

    var gotDidFinish: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false
    var gotPageWillChange: Bool = false
    var gotPageDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "Survey")

        guard case let Interaction.InteractionConfiguration.surveyV12(surveyConfiguration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spyInteractionDelegate = SpyInteractionDelegate()
        self.viewModel = SurveyViewModel(configuration: surveyConfiguration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate!)
        self.viewModel.delegate = self
    }

    func testSurveyMetadata() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.name, "Every Question Type")
        XCTAssertEqual(viewModel.advanceButtonText, "Boom")
        XCTAssertEqual(viewModel.interaction.id, "1")
        XCTAssertEqual(viewModel.validationErrorMessage, "You done goofed.")
        XCTAssertEqual(viewModel.introduction, "Please help us see how each question is formatted when returning a survey response to the server.")
        XCTAssertEqual(viewModel.thankYouMessage, "Thank you!")
        XCTAssertEqual(viewModel.isRequired, false)
        XCTAssertEqual(viewModel.questions.count, 16)

        XCTAssertEqual(viewModel.termsAndConditions?.linkLabel, "Terms & Conditions")

        self.viewModel.openTermsAndConditions()

        XCTAssertEqual(self.spyInteractionDelegate.openedURL, URL(string: "https://www.example.com/"))
    }

    func testSurveyQuestionBasics() {
        XCTAssertEqual(self.viewModel.questions[0].text, "Multichoice Optional")
        XCTAssertEqual(self.viewModel.questions[0].instructions, "select one")
    }

    func testOtherOptionSelection() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let otherQuestion = viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Choice questions have non-radio-button view models")
        }
        XCTAssertEqual(otherQuestion.choices.filter { $0.isSelected }.count, 0)
        otherQuestion.toggleChoice(at: 2)
        XCTAssertTrue(otherQuestion.choices[2].isSelected)
    }

    func testRadioButtonSelection() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let multichoiceOptional = viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Choice questions have non-radio-button view models")
        }

        XCTAssertEqual(multichoiceOptional.choices.filter { $0.isSelected }.count, 0)
        multichoiceOptional.toggleChoice(at: 0)
        XCTAssertTrue(multichoiceOptional.choices[0].isSelected)
        multichoiceOptional.toggleChoice(at: 1)
        XCTAssertTrue(self.gotSelectionDidChange)
        XCTAssertTrue(multichoiceOptional.choices[1].isSelected)
        XCTAssertFalse(multichoiceOptional.choices[0].isSelected)
        multichoiceOptional.toggleChoice(at: 1)
        XCTAssertTrue(multichoiceOptional.choices[1].isSelected)
    }

    func testRadioButtonValidation() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let multichoiceOptional = viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion,
            let multichoiceRequired = viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion
        else {
            return XCTFail("Choice questions have non-radio-button view models")
        }

        XCTAssertTrue(multichoiceOptional.isValid)
        multichoiceOptional.toggleChoice(at: 0)
        XCTAssertTrue(multichoiceOptional.isValid)

        XCTAssertFalse(multichoiceRequired.isValid)
        multichoiceRequired.toggleChoice(at: 0)
        XCTAssertTrue(multichoiceRequired.isValid)
        multichoiceRequired.toggleChoice(at: 0)
        XCTAssertTrue(multichoiceRequired.isValid)
    }

    func testCheckboxSelection() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let question = viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Choice questions have non-radio-button view models")
        }

        XCTAssertEqual(question.choices.filter { $0.isSelected }.count, 0)

        question.toggleChoice(at: 0)
        XCTAssertTrue(self.gotSelectionDidChange)
        XCTAssertTrue(question.choices[0].isSelected)

        self.gotSelectionDidChange = false

        question.toggleChoice(at: 1)
        XCTAssertTrue(self.gotSelectionDidChange)
        XCTAssertTrue(question.choices[0].isSelected)
        XCTAssertTrue(question.choices[1].isSelected)

        self.gotSelectionDidChange = false

        question.toggleChoice(at: 1)
        XCTAssertTrue(self.gotSelectionDidChange)
        XCTAssertFalse(question.choices[1].isSelected)
    }

    func testCheckboxValidation() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let multiselectOptional = viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequired = viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion,
            let multiselectOptionalWithLimits = viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequiredWithLimits = viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion
        else {
            return XCTFail("Choice questions have non-radio-button view models")
        }

        XCTAssertTrue(multiselectOptional.isValid)
        multiselectOptional.toggleChoice(at: 0)
        XCTAssertTrue(multiselectOptional.isValid)

        XCTAssertFalse(multiselectRequired.isValid)
        multiselectRequired.toggleChoice(at: 0)
        XCTAssertFalse(multiselectRequired.isValid, "Other text should be required.")
        multiselectRequired.choices[0].value = "Bar"
        XCTAssertTrue(multiselectRequired.isValid, "Implicit minimum of one selection (provided by server)")

        XCTAssertTrue(multiselectOptionalWithLimits.isValid, "Multiselect optional limits only enforced if something is selected")
        multiselectOptionalWithLimits.toggleChoice(at: 0)
        XCTAssertFalse(multiselectOptionalWithLimits.isValid, "Multiselect optional lower limit enforced when something is selected")
        multiselectOptionalWithLimits.toggleChoice(at: 1)
        XCTAssertTrue(multiselectOptionalWithLimits.isValid)
        multiselectOptionalWithLimits.toggleChoice(at: 2)
        XCTAssertFalse(multiselectOptionalWithLimits.isValid, "Multiselect optional other choice should enforce non-null value")
        multiselectOptionalWithLimits.choices[2].value = "Test"
        XCTAssertTrue(multiselectOptionalWithLimits.isValid)
        multiselectOptionalWithLimits.toggleChoice(at: 3)
        XCTAssertFalse(multiselectOptionalWithLimits.isValid, "Multiselect optional upper limit enforced when something is selected")

        XCTAssertFalse(multiselectRequiredWithLimits.isValid, "Multiselect required limits enforced even when nothing is selected")
        multiselectRequiredWithLimits.toggleChoice(at: 0)
        XCTAssertTrue(multiselectRequiredWithLimits.isValid)
        multiselectRequiredWithLimits.toggleChoice(at: 1)
        multiselectRequiredWithLimits.toggleChoice(at: 2)
        multiselectRequiredWithLimits.toggleChoice(at: 3)
        XCTAssertFalse(multiselectRequiredWithLimits.isValid)
    }

    func testFreeformValidation() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let freeformShortOptional = viewModel.questions[6] as? SurveyViewModel.FreeformQuestion,
            let freeformShortRequired = viewModel.questions[7] as? SurveyViewModel.FreeformQuestion,
            let freeformLongOptional = viewModel.questions[8] as? SurveyViewModel.FreeformQuestion,
            let freeformLongRequired = viewModel.questions[9] as? SurveyViewModel.FreeformQuestion
        else {
            return XCTFail("Freeform questions have non-freeform view models")
        }

        XCTAssertTrue(freeformShortOptional.isValid)
        XCTAssertFalse(freeformShortRequired.isValid)
        XCTAssertTrue(freeformLongOptional.isValid)
        XCTAssertFalse(freeformLongRequired.isValid)

        freeformShortRequired.value = " "
        XCTAssertFalse(freeformShortRequired.isValid)
        freeformShortRequired.value = "Yo"
        XCTAssertTrue(freeformShortRequired.isValid)

        freeformLongRequired.value = "Hey"
        XCTAssertTrue(freeformLongRequired.isValid)
    }

    func testRangeSelection() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let rangeNPS = viewModel.questions[10] as? SurveyViewModel.RangeQuestion else {
            return XCTFail("Weird view models")
        }

        XCTAssertEqual(rangeNPS.selectedValueIndex, nil)
        rangeNPS.selectValue(at: 0)
        XCTAssertEqual(rangeNPS.selectedValueIndex, 0)
        rangeNPS.selectValue(at: 1)
        XCTAssertTrue(self.gotSelectionDidChange)
        XCTAssertEqual(rangeNPS.selectedValueIndex, 1)
        rangeNPS.selectValue(at: 1)
        XCTAssertEqual(rangeNPS.selectedValueIndex, 1)

    }

    func testRangeValidation() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let rangeNPS = viewModel.questions[10] as? SurveyViewModel.RangeQuestion,
            let rangeHowDoYouFeel = viewModel.questions[11] as? SurveyViewModel.RangeQuestion
        else {
            return XCTFail("Weird view models")
        }

        XCTAssertTrue(rangeNPS.isValid)
        rangeNPS.selectValue(at: 0)
        XCTAssertTrue(rangeNPS.isValid)

        XCTAssertFalse(rangeHowDoYouFeel.isValid)
        rangeHowDoYouFeel.selectValue(at: 0)
        XCTAssertTrue(rangeHowDoYouFeel.isValid)
        rangeHowDoYouFeel.selectValue(at: 0)
        XCTAssertTrue(rangeHowDoYouFeel.isValid)
    }

    func testMarkedAsInvalid() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let multichoiceOptional = viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion,
            let multichoiceRequired = viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion,
            let multiselectOptional = viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequired = viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion,
            let multiselectOptionalWithLimits = viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequiredWithLimits = viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion,
            let freeformShortOptional = viewModel.questions[6] as? SurveyViewModel.FreeformQuestion,
            let freeformShortRequired = viewModel.questions[7] as? SurveyViewModel.FreeformQuestion,
            let freeformLongOptional = viewModel.questions[8] as? SurveyViewModel.FreeformQuestion,
            let freeformLongRequired = viewModel.questions[9] as? SurveyViewModel.FreeformQuestion,
            let rangeNPS = viewModel.questions[10] as? SurveyViewModel.RangeQuestion,
            let rangeHowDoYouFeel = viewModel.questions[11] as? SurveyViewModel.RangeQuestion,
            let rangeHowCloseToZero = viewModel.questions[12] as? SurveyViewModel.RangeQuestion,
            let rangeMissingLabels = viewModel.questions[13] as? SurveyViewModel.RangeQuestion,
            let rangeEmptyLabels = viewModel.questions[14] as? SurveyViewModel.RangeQuestion,
            let rangeMissingMinMax = viewModel.questions[15] as? SurveyViewModel.RangeQuestion
        else {
            return XCTFail("Weird view models")
        }

        XCTAssertFalse(multichoiceOptional.isMarkedAsInvalid)
        XCTAssertFalse(multichoiceRequired.isMarkedAsInvalid)
        XCTAssertFalse(multiselectOptional.isMarkedAsInvalid)
        XCTAssertFalse(multiselectRequired.isMarkedAsInvalid)
        XCTAssertFalse(multiselectOptionalWithLimits.isMarkedAsInvalid)
        XCTAssertFalse(multiselectRequiredWithLimits.isMarkedAsInvalid)
        XCTAssertFalse(freeformShortOptional.isMarkedAsInvalid)
        XCTAssertFalse(freeformShortRequired.isMarkedAsInvalid)
        XCTAssertFalse(freeformLongOptional.isMarkedAsInvalid)
        XCTAssertFalse(freeformLongRequired.isMarkedAsInvalid)
        XCTAssertFalse(rangeNPS.isMarkedAsInvalid)
        XCTAssertFalse(rangeHowDoYouFeel.isMarkedAsInvalid)
        XCTAssertFalse(rangeHowCloseToZero.isMarkedAsInvalid)
        XCTAssertFalse(rangeMissingLabels.isMarkedAsInvalid)
        XCTAssertFalse(rangeEmptyLabels.isMarkedAsInvalid)
        XCTAssertFalse(rangeMissingMinMax.isMarkedAsInvalid)

        // Force "sticky" validation
        viewModel.advance()
        XCTAssertFalse(self.gotDidFinish)

        XCTAssertFalse(multichoiceOptional.isMarkedAsInvalid)
        XCTAssertFalse(multiselectOptional.isMarkedAsInvalid)
        XCTAssertFalse(multiselectOptionalWithLimits.isMarkedAsInvalid)
        XCTAssertFalse(freeformShortOptional.isMarkedAsInvalid)
        XCTAssertFalse(freeformLongOptional.isMarkedAsInvalid)
        XCTAssertFalse(rangeNPS.isMarkedAsInvalid)
        XCTAssertFalse(rangeHowCloseToZero.isMarkedAsInvalid)
        XCTAssertFalse(rangeMissingLabels.isMarkedAsInvalid)
        XCTAssertFalse(rangeEmptyLabels.isMarkedAsInvalid)
        XCTAssertFalse(rangeMissingMinMax.isMarkedAsInvalid)

        XCTAssertTrue(multichoiceRequired.isMarkedAsInvalid)
        XCTAssertTrue(multiselectRequired.isMarkedAsInvalid)
        XCTAssertTrue(multiselectRequiredWithLimits.isMarkedAsInvalid)
        XCTAssertTrue(freeformShortRequired.isMarkedAsInvalid)
        XCTAssertTrue(freeformLongRequired.isMarkedAsInvalid)
        XCTAssertTrue(rangeHowDoYouFeel.isMarkedAsInvalid)

        self.gotValidationDidChange = false
        multichoiceRequired.toggleChoice(at: 0)
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(multichoiceRequired.isMarkedAsInvalid)

        self.gotValidationDidChange = false
        multiselectRequired.toggleChoice(at: 0)
        multiselectRequired.choices[0].value = "Foo"
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(multiselectRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        multiselectRequired.toggleChoice(at: 0)
        XCTAssertFalse(self.gotValidationDidChange)
        XCTAssertFalse(multiselectRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        multiselectRequiredWithLimits.toggleChoice(at: 0)
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(multiselectRequiredWithLimits.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        multiselectRequiredWithLimits.toggleChoice(at: 1)
        multiselectRequiredWithLimits.toggleChoice(at: 2)
        multiselectRequiredWithLimits.toggleChoice(at: 3)
        XCTAssertFalse(self.gotValidationDidChange)
        XCTAssertFalse(multiselectRequiredWithLimits.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        freeformShortRequired.value = "Yo"
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(freeformShortRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        freeformShortRequired.value = " "
        XCTAssertFalse(self.gotValidationDidChange)
        XCTAssertFalse(freeformShortRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        freeformLongRequired.value = "Hey"
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(freeformLongRequired.isMarkedAsInvalid)
        self.gotValidationDidChange = false
        freeformLongRequired.value = ""
        XCTAssertFalse(self.gotValidationDidChange)
        XCTAssertFalse(freeformLongRequired.isMarkedAsInvalid, "Should not re-validate until submit")

        self.gotValidationDidChange = false
        rangeHowDoYouFeel.selectValue(at: 4)
        XCTAssertTrue(self.gotValidationDidChange)
        XCTAssertFalse(rangeHowDoYouFeel.isMarkedAsInvalid)
    }

    func testSurveyAnswers() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        guard let multichoiceOptional = viewModel.questions[0] as? SurveyViewModel.ChoiceQuestion,
            let multichoiceRequired = viewModel.questions[1] as? SurveyViewModel.ChoiceQuestion,
            let multiselectOptional = viewModel.questions[2] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequired = viewModel.questions[3] as? SurveyViewModel.ChoiceQuestion,
            let multiselectOptionalWithLimits = viewModel.questions[4] as? SurveyViewModel.ChoiceQuestion,
            let multiselectRequiredWithLimits = viewModel.questions[5] as? SurveyViewModel.ChoiceQuestion,
            let freeformShortOptional = viewModel.questions[6] as? SurveyViewModel.FreeformQuestion,
            let freeformShortRequired = viewModel.questions[7] as? SurveyViewModel.FreeformQuestion,
            let freeformLongOptional = viewModel.questions[8] as? SurveyViewModel.FreeformQuestion,
            let freeformLongRequired = viewModel.questions[9] as? SurveyViewModel.FreeformQuestion,
            let rangeNPS = viewModel.questions[10] as? SurveyViewModel.RangeQuestion,
            let rangeHowDoYouFeel = viewModel.questions[11] as? SurveyViewModel.RangeQuestion,
            let rangeHowCloseToZero = viewModel.questions[12] as? SurveyViewModel.RangeQuestion,
            let rangeMissingLabels = viewModel.questions[13] as? SurveyViewModel.RangeQuestion,
            let rangeEmptyLabels = viewModel.questions[14] as? SurveyViewModel.RangeQuestion,
            let rangeMissingMinMax = viewModel.questions[15] as? SurveyViewModel.RangeQuestion
        else {
            return XCTFail("Freeform questions have non-freeform view models")
        }

        XCTAssertTrue(viewModel.response.questionResponses.values.allSatisfy({ $0 == .empty }))

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

        viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertTrue(self.gotDidFinish)

        XCTAssertEqual(
            self.spyInteractionDelegate.sentSurveyResponse?.questionResponses,
            [
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
        XCTAssertEqual(self.spyInteractionDelegate.engagedEvent?.codePointName, "com.apptentive#Survey#submit")
        XCTAssertEqual(
            self.spyInteractionDelegate.responses,
            [
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

        XCTAssertEqual(
            self.spyInteractionDelegate.lastResponse,
            [
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

        XCTAssertEqual(self.spyInteractionDelegate.lastResponse, [:])
    }

    func testBranchedSurvey() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "SurveyBranched")

        guard case let Interaction.InteractionConfiguration.surveyV12(surveyConfiguration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.viewModel = SurveyViewModel(configuration: surveyConfiguration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate!)
        self.viewModel.delegate = self

        self.viewModel.launch()

        XCTAssertEqual(self.viewModel.currentPage.description, "Please tell us about your experience with our survey builder.")

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertNil(self.viewModel.currentPage.description)

        guard let firstQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Expected first question to be choice question")
        }

        XCTAssertEqual(firstQuestion.text, "Do you love our current survey building and management experience?")

        firstQuestion.toggleChoice(at: 0)

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertNil(self.viewModel.currentPage.description)

        guard let secondQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Expected second question to be choice question")
        }

        XCTAssertEqual(secondQuestion.text, "Happy to hear! What do you love most about our survey experience?")

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertNil(self.viewModel.currentPage.description)

        guard let thirdQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Expected third question to be choice question")
        }

        XCTAssertEqual(thirdQuestion.text, "Which two survey features are the most important to you?")

        thirdQuestion.toggleChoice(at: 0)

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertNil(self.viewModel.currentPage.description)

        guard let fourthQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Expected fourth question to be choice question")
        }

        XCTAssertEqual(fourthQuestion.text, "We are testing our new Survey Logic capabilities in this survey! Did you love this new survey experience?")

        fourthQuestion.toggleChoice(at: 1)
        self.spyInteractionDelegate.matchingAdvanceLogicIndex = 1

        self.viewModel.advance()
        self.waitForSurveyLogic()

        self.spyInteractionDelegate.matchingAdvanceLogicIndex = 0

        XCTAssertNil(self.viewModel.currentPage.description)

        guard let fifthQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.FreeformQuestion else {
            return XCTFail("Expected fifth question to be choice question")
        }

        XCTAssertEqual(fifthQuestion.text, "What would you improve in this new survey experience with logic?")

        self.viewModel.advance()
        self.waitForSurveyLogic()

        guard let lastQuestion = self.viewModel.currentPage.questions.first as? SurveyViewModel.ChoiceQuestion else {
            return XCTFail("Expected last question to be choice question")
        }

        XCTAssertEqual(lastQuestion.text, "Can we contact you for additional feedback or testing to help us improve our Survey Logic features?")

        lastQuestion.toggleChoice(at: 1)

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertEqual(self.viewModel.currentPage.description, "Thank you for your valuable time. Your feedback will be used to help us improve our features for you!")

        guard let response = self.spyInteractionDelegate.sentSurveyResponse else {
            return XCTFail("Expected survey response to exist")
        }

        XCTAssertEqual(
            response.questionResponses,
            [
                "question_1": .answered([.choice("question_1_answer_1")]),
                "question_2": .empty,
                "question_3": .skipped,
                "question_4": .answered([.choice("question_3_answer_1")]),
                "question_5": .answered([.choice("question_5_answer_2")]),
                "question_6": .skipped,
                "question_7": .empty,
                "question_8": .answered([.choice("question_8_answer_2")]),
            ])

        XCTAssertEqual(self.viewModel.advanceButtonText, "Done")

        self.viewModel.advance()
        self.waitForSurveyLogic()

        XCTAssertTrue(self.gotDidFinish)
    }

    func waitForSurveyLogic() {
        let expectation = XCTestExpectation()

        // Needed because survey logic happens on background thread.
        DispatchQueue.main.async {
            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 1)
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
