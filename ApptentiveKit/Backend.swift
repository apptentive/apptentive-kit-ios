//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

class Backend {
    let queue: DispatchQueue

    private var conversation: Conversation
    private var client: HTTPClient<ApptentiveV9API>?

    init(queue: DispatchQueue, environment: Environment) {
        self.queue = queue
        self.conversation = Conversation(environment: environment)
    }

    func connect(appCredentials: Apptentive.AppCredentials, baseURL: URL, completion: @escaping ((Bool) -> Void)) {
        self.client = HTTPClient<ApptentiveV9API>(requestor: URLSession.shared, baseURL: baseURL)
        conversation.appCredentials = appCredentials
        self.client?.request(.createConversation(conversation)) { (result: (Result<ConversationResponse, Error>)) in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    completion(true)

                case .failure(_):
                    completion(false)
                }
            }
        }
    }
}
