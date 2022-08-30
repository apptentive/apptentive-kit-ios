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
    var viewModel: SurveyViewModel?
    var spySender: SpyInteractionDelegate?

    var gotDidSubmit: Bool = false
    var gotValidationDidChange: Bool = false
    var gotSelectionDidChange: Bool = false

    override func setUpWithError() throws {
        let interaction = try InteractionTestHelpers.loadInteraction(named: "Survey")

        guard case let Interaction.InteractionConfiguration.survey(surveyConfiguration) = interaction.configuration else {
            return XCTFail("Unable to create view model")
        }

        self.spySender = SpyInteractionDelegate()
        self.viewModel = SurveyViewModel(configuration: surveyConfiguration, interaction: interaction, interactionDelegate: self.spySender!)
        self.viewModel?.delegate = self
    }

    func testSurveyMetadata() {
        guard let viewModel = self.viewModel else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(viewModel.name, "Every Question Type")
        XCTAssertEqual(viewModel.submitButtonText, "Boom")
        XCTAssertEqual(viewModel.interaction.id, "1")
        XCTAssertEqual(viewModel.validationErrorMessage, "You done goofed.")
        XCTAssertEqual(viewModel.introduction, "Please help us see how each question is formatted when returning a survey response to the server.")
        XCTAssertEqual(viewModel.thankYouMessage, "Thank you!")
        XCTAssertEqual(viewModel.isRequired, false)
        XCTAssertEqual(viewModel.questions.count, 16)

        XCTAssertEqual(viewModel.termsAndConditionsLinkText, "Terms and Conditions")

        self.viewModel?.openTermsAndConditions()

        XCTAssertEqual(self.spySender?.openedURL, URL(string: "https://apptentive.com/privacy"))
    }

    func testSurveyQuestionBasics() {
        guard let questions = self.viewModel?.questions else {
            return XCTFail("Unable to load view model")
        }

        XCTAssertEqual(questions[0].text, "Multichoice Optional")
        XCTAssertEqual(questions[0].instructions, "select one")
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
        XCTAssertTrue(multiselectOptionalWithLimits.isValid)
        multiselectOptionalWithLimits.toggleChoice(at: 1)
        multiselectOptionalWithLimits.toggleChoice(at: 2)
        multiselectOptionalWithLimits.toggleChoice(at: 3)
        XCTAssertFalse(multiselectOptionalWithLimits.isValid, "Multiselect optional limits enforced when something is selected")

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
        viewModel.submit()
        XCTAssertFalse(self.gotDidSubmit)

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

        XCTAssertEqual(viewModel.response.answers, [String: [Answer]]())

        multichoiceOptional.toggleChoice(at: 0)
        multichoiceRequired.toggleChoice(at: 1)

        multiselectOptional.toggleChoice(at: 0)
        multiselectOptional.toggleChoice(at: 2)
        multiselectRequired.toggleChoice(at: 0)
        multiselectRequired.choices[0].value = "Bar"
        multiselectOptionalWithLimits.toggleChoice(at: 0)
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

        viewModel.submit()

        XCTAssertTrue(self.gotDidSubmit)

        XCTAssertEqual(
            self.spySender?.sentSurveyResponse?.answers,
            [
                "2": [Answer.choice("3")],
                "6": [Answer.choice("8")],
                "11": [Answer.choice("12"), Answer.choice("14")],
                "15": [Answer.other("16", "Bar")],
                "18": [Answer.choice("19")],
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
        XCTAssertEqual(self.spySender?.engagedEvent?.codePointName, "com.apptentive#Survey#submit")
        XCTAssertEqual(
            self.spySender?.responses,
            [
                "2": [Answer.choice("3")],
                "6": [Answer.choice("8")],
                "11": [Answer.choice("12"), Answer.choice("14")],
                "15": [Answer.other("16", "Bar")],
                "18": [Answer.choice("19")],
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
    }

    func surveyViewModelDidSubmit(_ viewModel: SurveyViewModel) {
        self.gotDidSubmit = true
    }

    func surveyViewModelValidationDidChange(_ viewModel: SurveyViewModel) {
        self.gotValidationDidChange = true
    }

    func surveyViewModelSelectionDidChange(_ viewModel: SurveyViewModel) {
        self.gotSelectionDidChange = true
    }
}
