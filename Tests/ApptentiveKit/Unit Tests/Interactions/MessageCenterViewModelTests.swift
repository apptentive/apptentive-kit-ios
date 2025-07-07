//
//  MessageCenterViewModelTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 9/14/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor struct MessageCenterViewModelTests {
    var environment: MockEnvironment
    var viewModel: MessageCenterViewModel
    var spyInteractionDelegate: SpyInteractionDelegate
    var spyDelegate: SpyViewModelDelegate

    init() throws {
        self.environment = MockEnvironment()
        try MockEnvironment.cleanContainerURL()

        let interaction = try InteractionTestHelpers.loadInteraction(named: "MessageCenter")
        guard case let Interaction.InteractionConfiguration.messageCenter(configuration) = interaction.configuration else {
            throw TestError(reason: "Unexpected interaction type")
        }
        self.spyInteractionDelegate = SpyInteractionDelegate()
        self.viewModel = MessageCenterViewModel(configuration: configuration, interaction: interaction, interactionDelegate: self.spyInteractionDelegate)

        self.spyDelegate = SpyViewModelDelegate()
        self.viewModel.delegate = self.spyDelegate
    }

    @Test func testMesssageCenterStrings() async throws {
        #expect(self.viewModel.headingTitle == "Message Center")
        #expect(self.viewModel.branding == "Powered By Apptentive")
        #expect(self.viewModel.composerTitle == "New Message")
        #expect(self.viewModel.composerSendButtonTitle == "Send")
        #expect(self.viewModel.composerAttachButtonTitle == "Attach")
        #expect(self.viewModel.composerPlaceholderText == "Please leave detailed feedback")
        #expect(self.viewModel.composerCloseConfirmBody == "Are you sure you want to discard this message?")
        #expect(self.viewModel.composerCloseDiscardButtonTitle == "Discard")
        #expect(self.viewModel.composerCloseCancelButtonTitle == "Cancel")
        #expect(self.viewModel.greetingTitle == "Hello!")
        #expect(self.viewModel.greetingBody == "We'd love to get feedback from you on our app. The more details you can provide, the better.")
        #expect(self.viewModel.greetingImageURL == URL(string: "https://dfuvhehs12k8c.cloudfront.net/assets/app-icon/music.png"))
        #expect(self.viewModel.statusBody == "We will respond to your message soon.")

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        #expect(self.spyInteractionDelegate.automatedMessageBody == "We're sorry to hear that you don't love FooApp! Is there anything we could do to make it better?")
    }

    @Test func testLaunchEvent() {
        self.viewModel.launch()

        #expect(self.spyInteractionDelegate.engagedEvent?.codePointName == "com.apptentive#MessageCenter#launch")
    }

    @Test func testCancelEvent() {
        self.viewModel.cancel()

        #expect(self.spyInteractionDelegate.engagedEvent?.codePointName == "com.apptentive#MessageCenter#cancel")
    }

    @Test func testReadEvent() async throws {
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        self.viewModel.markMessageAsRead(at: .init(row: 0, section: 0))

        #expect(self.spyInteractionDelegate.engagedEvent?.userInfo == .messageInfo(.init(id: "abc")))
    }

    @Test func testListView() async throws {
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        try #require(self.viewModel.numberOfMessageGroups > 0)
        #expect(self.viewModel.numberOfMessagesInGroup(at: 0) == 1)
        #expect(self.viewModel.message(at: [0, 0]).body == "Test Body")
    }

    // TODO: Test Draft Editing Methods

    @Test func testSendMessage() async throws {
        self.viewModel.draftMessageBody = "Test Message"

        // Setting draft message on interaction delegate is async but awkward to expose as such.
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        try await self.viewModel.sendMessage()

        #expect(self.spyInteractionDelegate.sentMessage?.body == "Test Message")
        #expect(self.spyInteractionDelegate.engagedEvent?.codePointName == "com.apptentive#MessageCenter#send")
    }

    @Test func testDiffSections() {
        // Using example from https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/TableView_iPhone/ManageInsertDeleteRow/ManageInsertDeleteRow.html#//apple_ref/doc/uid/TP40007451-CH10-SW20
        let oldStates = ["Arizona", "California", "Delaware", "New Jersey", "Washington"]
        var states = oldStates

        states.remove(at: 4)
        states.remove(at: 2)

        states.insert("Alaska", at: 0)
        states.insert("Georgia", at: 3)
        states.insert("Virginia", at: 5)

        var expectedDeleteIndexes = IndexSet()
        var expectedInsertIndexes = IndexSet()

        expectedDeleteIndexes.insert(2)
        expectedDeleteIndexes.insert(4)

        expectedInsertIndexes.insert(0)
        expectedInsertIndexes.insert(3)
        expectedInsertIndexes.insert(5)

        let (deleteIndexes, insertIndexes) = MessageCenterViewModel.diffSortedCollection(from: oldStates, to: states)

        #expect(deleteIndexes == expectedDeleteIndexes)
        #expect(insertIndexes == expectedInsertIndexes)
    }

    @Test func testDiffRows() {
        let message1 = MessageCenterViewModel.Message(
            nonce: "1", direction: .sentFromDashboard(.unread(messageID: "id100")), isAutomated: false, attachments: [], sender: nil, body: "One", sentDate: Date(timeIntervalSinceNow: 12 * 60 * 60), statusText: "100", accessibilityLabel: "",
            accessibilityHint: "")
        let message2 = MessageCenterViewModel.Message(
            nonce: "2", direction: .sentFromDashboard(.unread(messageID: "id200")), isAutomated: false, attachments: [], sender: nil, body: "Two", sentDate: Date(timeIntervalSinceNow: 24 * 60 * 60), statusText: "200", accessibilityLabel: "",
            accessibilityHint: "")
        let message3 = MessageCenterViewModel.Message(
            nonce: "3", direction: .sentFromDashboard(.unread(messageID: "id300")), isAutomated: false, attachments: [], sender: nil, body: "Three", sentDate: Date(timeIntervalSinceNow: 36 * 60 * 60), statusText: "300", accessibilityLabel: "",
            accessibilityHint: "")
        let message4 = MessageCenterViewModel.Message(
            nonce: "4", direction: .sentFromDashboard(.unread(messageID: "id400")), isAutomated: false, attachments: [], sender: nil, body: "Four", sentDate: Date(timeIntervalSinceNow: 48 * 60 * 60), statusText: "400", accessibilityLabel: "",
            accessibilityHint: "")
        let message5 = MessageCenterViewModel.Message(
            nonce: "5", direction: .sentFromDashboard(.unread(messageID: "id500")), isAutomated: false, attachments: [], sender: nil, body: "Five", sentDate: Date(timeIntervalSinceNow: 60 * 60 * 60), statusText: "500", accessibilityLabel: "",
            accessibilityHint: "")
        let message6 = MessageCenterViewModel.Message(
            nonce: "6", direction: .sentFromDashboard(.unread(messageID: "id600")), isAutomated: false, attachments: [], sender: nil, body: "Six", sentDate: Date(timeIntervalSinceNow: 72 * 60 * 60), statusText: "600", accessibilityLabel: "",
            accessibilityHint: "")
        let message7 = MessageCenterViewModel.Message(
            nonce: "7", direction: .sentFromDashboard(.unread(messageID: "id700")), isAutomated: false, attachments: [], sender: nil, body: "Seven", sentDate: Date(timeIntervalSinceNow: 96 * 60 * 60), statusText: "700", accessibilityLabel: "",
            accessibilityHint: "")

        let changedMessage2 = MessageCenterViewModel.Message(
            nonce: "2", direction: .sentFromDashboard(.unread(messageID: "id200")), isAutomated: false, attachments: [], sender: nil, body: "Two modified", sentDate: Date(timeIntervalSinceNow: 24 * 60 * 60), statusText: "200", accessibilityLabel: "",
            accessibilityHint: "")

        let oldGroupedMessages = [
            [message1, message2, message3],
            [message4, message6],
        ]

        let newGroupedMessages = [
            [message1],
            [changedMessage2],
            [message4, message5, message6, message7],
        ]

        self.viewModel.update(from: oldGroupedMessages, to: newGroupedMessages)

        #expect(self.spyDelegate.deletedRows == [IndexPath(row: 2, section: 0)])  // Deletes are relative to old groupings
        #expect(self.spyDelegate.updatedRows == [IndexPath(row: 0, section: 1)])  // Updates are relative to new groupings
        #expect(self.spyDelegate.insertedRows == [IndexPath(row: 1, section: 2), IndexPath(row: 3, section: 2)])  // Inserts are relative to new groupings
    }

    @Test func testSettingEmail() {
        self.viewModel.emailAddress = "test email"
        #expect(self.spyInteractionDelegate.personEmailAddress == nil)

        self.viewModel.commitProfileEdits()
        #expect(self.spyInteractionDelegate.personEmailAddress == "test email")

        self.viewModel.emailAddress = "fake email"
        self.viewModel.cancelProfileEdits()
        #expect(self.viewModel.emailAddress == "test email")

        self.viewModel.emailAddress = " "
        self.viewModel.commitProfileEdits()
        #expect(self.spyInteractionDelegate.personEmailAddress == nil)
    }

    @Test func testSettingName() {
        self.viewModel.name = "name"
        #expect(self.spyInteractionDelegate.personName == nil)

        self.viewModel.commitProfileEdits()
        #expect(self.spyInteractionDelegate.personName == "name")

        self.viewModel.name = "fake name"
        self.viewModel.cancelProfileEdits()
        #expect(self.viewModel.name == "name")

        self.viewModel.name = " "
        self.viewModel.commitProfileEdits()
        #expect(self.spyInteractionDelegate.personName == nil)
    }

    class SpyViewModelDelegate: MessageCenterViewModelDelegate {
        var beginEndBalance = 0
        var insertedSections = IndexSet()
        var deletedSections = IndexSet()
        var deletedRows = Set<IndexPath>()
        var updatedRows = Set<IndexPath>()
        var insertedRows = Set<IndexPath>()

        func messageCenterViewModelDidBeginUpdates(_: MessageCenterViewModel) {
            beginEndBalance += 1
        }

        func messageCenterViewModel(_: MessageCenterViewModel, didInsertSectionsWith sectionIndexes: IndexSet) {
            self.insertedSections = sectionIndexes
        }

        func messageCenterViewModel(_: MessageCenterViewModel, didDeleteSectionsWith sectionIndexes: IndexSet) {
            self.deletedSections = sectionIndexes
        }

        func messageCenterViewModel(_: MessageCenterViewModel, didDeleteRowsAt indexPaths: [IndexPath]) {
            self.deletedRows = Set(indexPaths)
        }

        func messageCenterViewModel(_: MessageCenterViewModel, didUpdateRowsAt indexPaths: [IndexPath]) {
            self.updatedRows = Set(indexPaths)
        }

        func messageCenterViewModel(_: MessageCenterViewModel, didInsertRowsAt indexPaths: [IndexPath]) {
            self.insertedRows = Set(indexPaths)
        }

        func messageCenterViewModelDidEndUpdates(_: MessageCenterViewModel) {
            beginEndBalance -= 1
        }

        func messageCenterViewModelMessageListDidLoad(_: MessageCenterViewModel) {}

        func messageCenterViewModelDraftMessageDidUpdate(_: MessageCenterViewModel) {}

        func messageCenterViewModel(_: MessageCenterViewModel, didFailToRemoveAttachmentAt index: Int, with error: Error) {}

        func messageCenterViewModel(_: MessageCenterViewModel, didFailToAddAttachmentWith error: Error) {}

        func messageCenterViewModel(_: MessageCenterViewModel, didFailToSendMessageWith error: Error) {}

        func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFinishAt index: Int, inMessageAt indexPath: IndexPath) {}

        func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFailAt index: Int, inMessageAt indexPath: IndexPath, with error: Error) {}

        func messageCenterViewModel(_: ApptentiveKit.MessageCenterViewModel, profilePhoto: UIImage, didDownloadFor indexPath: IndexPath) {}
    }
}
