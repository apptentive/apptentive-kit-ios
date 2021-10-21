//
//  MessageManager.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Provides multiple ways to interact with the MessageList.
class MessageManager {

    /// The Message List object.
    ///
    /// The message list is fetched from the server on launch and saved to disk.
    var messageList: MessageList? {
        didSet {
            self.lastFetchDate = Date()
        }
    }

    var lastFetchDate: Date?

    /// The persistence repository used for the message list.
    var messageListRepository: PropertyListRepository<MessageList>? {
        didSet {
            do {
                guard let repository = messageListRepository, repository.fileExists else {
                    ApptentiveLogger.default.debug("No messages in persistence storage.")
                    return
                }
                let savedMessageList = try repository.load()
                self.messageList = savedMessageList
            } catch let error {
                ApptentiveLogger.default.error("Unable to load messages from peristence: \(error)")
            }
        }
    }

    static func createRepository(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListRepository<MessageList> {
        return PropertyListRepository<MessageList>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    func saveMessagesToDisk() throws {
        if let messageListRepository = self.messageListRepository,
            let messageList = self.messageList
        {
            try messageListRepository.save(messageList)
        }
    }
}
