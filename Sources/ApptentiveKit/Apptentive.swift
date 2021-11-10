//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The main interface to the Apptentive SDK.
public class Apptentive: NSObject, EnvironmentDelegate, InteractionDelegate {
    /// The shared instance of the Apptentive SDK.
    ///
    /// This object is created lazily upon access.
    @objc public static let shared = Apptentive()

    /// An object that overrides the `InteractionPresenter` class used to display interactions to the user.
    public var interactionPresenter: InteractionPresenter

    /// The theme to apply to Apptentive UI.
    ///
    /// This property must be set before calling `register(credentials:)`.
    public var theme: UITheme = .apptentive

    /// The object representing the terms of service at the bottom of surveys.
    public var termsOfService: TermsOfService?

    /// The name of the person using the app, if available.
    @objc public var personName: String? {
        get {
            self.person.name
        }
        set {
            self.person.name = newValue

            ApptentiveLogger.default.debug("Setting person name to “\(newValue)”.")

            self.updateConversationPerson()
        }
    }

    /// The email address of the person using the app, if available.
    @objc public var personEmailAddress: String? {
        get {
            self.person.emailAddress
        }
        set {
            self.person.emailAddress = newValue

            ApptentiveLogger.default.debug("Setting person email address to “\(newValue)”.")

            self.updateConversationPerson()
        }
    }

    /// The string used by the mParticle integration to identify the current user.
    @objc public var mParticleID: String? {
        get {
            self.person.mParticleID
        }
        set {
            self.person.mParticleID = newValue

            ApptentiveLogger.default.debug("Setting person mParticle ID to “\(newValue)”.")

            self.updateConversationPerson()
        }
    }

    /// The custom data assocated with the person using the app.
    ///
    /// Supported types are `String`, `Bool`, and numbers.
    public var personCustomData: CustomData {
        get {
            self.person.customData
        }
        set {
            self.person.customData = newValue

            ApptentiveLogger.default.debug("Setting person custom data to \(String(describing: newValue)).")

            self.updateConversationPerson()
        }
    }

    /// The custom data associated with the device running the app.
    ///
    /// Supported types are `String`, `Bool`, and numbers.
    public var deviceCustomData: CustomData {
        get {
            self.device.customData
        }
        set {
            self.device.customData = newValue

            ApptentiveLogger.default.debug("Setting device custom data to \(String(describing: newValue)).")

            self.updateConversationDevice()
        }
    }

    /// Indicates a theme that will be applied to Apptentive UI.
    public enum UITheme {
        /// Apptentive cross-platform look and feel.
        case apptentive

        /// iOS default look and feel.
        case none
    }

    /// Provides the SDK with the credentials necessary to connect to the Apptentive API.
    /// - Parameters:
    ///   - credentials: The `AppCredentials` object containing your Apptentive key and signature.
    ///   - completion: A completion handler that is called after the SDK succeeds or fails to connect to the Apptentive API.

    public func register(credentials: AppCredentials, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        if case .apptentive = self.theme {
            ApptentiveLogger.interaction.info("Using Apptentive theme for interaction UI.")
            self.applyApptentiveTheme()
        }

        if !self.environment.isTesting {
            if credentials.key.isEmpty || credentials.signature.isEmpty {
                assertionFailure("App key or signature is missing.")
            } else if !credentials.key.hasPrefix("IOS-") {
                assertionFailure("Invalid app key. Please check the dashboard for the correct app key.")
            }
        }

        self.backendQueue.async {
            self.backend.connect(appCredentials: credentials) { result in
                switch result {
                case .success:
                    completion?(.success(true))
                    ApptentiveLogger.default.info("Apptentive SDK registered successfully.")

                case .failure(let error):
                    completion?(.failure(error))
                    ApptentiveLogger.default.error("Failed to register Apptentive SDK: \(error)")
                    if !self.environment.isTesting {
                        assertionFailure("Failed to register Apptentive SDK: Please double-check that the app key, signature, and the url is correct.")
                    }
                }
            }
        }
    }

    /// Contains the credentials necessary to connect to the Apptentive API.
    public struct AppCredentials: Codable, Equatable {
        let key: String
        let signature: String

        /// Creates a new `AppCredentials` object.
        /// - Parameters:
        ///   - key: The Apptentive Key that should be used when connecting to the Apptentive API.
        ///   - signature: The Apptentive Signature that should be used when connecting to the Apptentive API.
        public init(key: String, signature: String) {
            self.key = key
            self.signature = signature
        }
    }

    /// Engages the specified event, using the view controller (if any) as the presenting view controller for any interactions.
    /// - Parameters:
    ///   - event: The event to engage.
    ///   - viewController: The view controller from which any interactions triggered by this (or future) event(s) should be presented.
    ///   - completion: A completion handler that is called with a boolean indicating whether or not an interaction was presented.
    public func engage(event: Event, from viewController: UIViewController? = nil, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        if let presentingViewController = viewController {
            self.interactionPresenter.presentingViewController = presentingViewController
        }

        self.backendQueue.async {
            self.backend.engage(event: event, completion: completion)
        }
    }

    /// Sends the specified text as a hidden message to the app's dashboard.
    /// - Parameter text: The text to send in the body of the message.
    @objc(sendAttachmentText:)
    public func sendAttachment(_ text: String) {
        self.sendMessage(Message(body: text, isHidden: true))
    }

    /// Sends the specified image (encoded as a JPEG at 95% quality) attached to a hidden message to the app's dashboard.
    /// - Parameter image: The image to encode and send.
    @objc(sendAttachmentImage:)
    public func sendAttachment(_ image: UIImage) {
        let attachment = Message.Attachment(mediaType: "image/jpeg", filename: "image", url: nil, data: image.jpegData(compressionQuality: 0.95))
        self.sendMessage(Message(attachments: [attachment], isHidden: true))
    }

    /// Sends the specified data attached to a hidden message to the app's dashboard.
    /// - Parameters:
    ///   - fileData: The contents of the file.
    ///   - mediaType: The media type for the file.
    @objc(sendAttachmentData:mimeType:)
    public func sendAttachment(_ fileData: Data, mediaType: String) {
        let attachment = Message.Attachment(mediaType: mediaType, filename: "file", url: nil, data: fileData)
        self.sendMessage(Message(attachments: [attachment], isHidden: true))
    }

    /// Creates a new Apptentive SDK object using the specified URL to communicate with the Apptentive API.
    ///
    /// This should only be used for testing the SDK against a server other than the production Apptentive API server.
    /// - Parameter apiBaseURL: The URL to use to communicate with the Apptentive API.
    public convenience init(apiBaseURL: URL) {
        self.init(baseURL: apiBaseURL)
    }

    // MARK: - Internal

    let baseURL: URL
    let backendQueue: DispatchQueue
    let backend: Backend
    var environment: GlobalEnvironment
    let containerDirectory: String

    init(baseURL: URL? = nil, containerDirectory: String? = nil, backendQueue: DispatchQueue? = nil, environment: GlobalEnvironment? = nil) {
        if Self.alreadyInitialized {
            assertionFailure("Attempting to instantiate an Apptentive object but an instance already exists.")
        }

        Self.alreadyInitialized = true

        // swift-format-ignore
        self.baseURL = baseURL ?? URL(string: "https://api.apptentive.com/")!
        self.backendQueue = backendQueue ?? DispatchQueue(label: "com.apptentive.backend", qos: .default, autoreleaseFrequency: .workItem)
        self.environment = environment ?? Environment()
        self.containerDirectory = containerDirectory ?? "com.apptentive.feedback"

        self.backend = Backend(queue: self.backendQueue, environment: self.environment, baseURL: self.baseURL)

        self.interactionPresenter = InteractionPresenter()

        self.person = self.backend.conversation.person
        self.device = self.backend.conversation.device

        super.init()

        self.environment.delegate = self
        self.backend.frontend = self
        self.interactionPresenter.delegate = self

        if self.environment.isProtectedDataAvailable {
            self.protectedDataDidBecomeAvailable(self.environment)
        }

        // The SDK will be initialized after the system sends the
        // ApplicationWillEnterForeground notification, meaning that
        // the tasks below have to be run explicitly.
        if self.environment.isInForeground {
            self.engage(event: .launch())

            self.backendQueue.async {
                self.backend.invalidateEngagementManifestForDebug(environment: self.environment)
            }
        }

        ApptentiveLogger.default.info("Apptentive SDK Initialized.")
    }

    static var alreadyInitialized = false

    // MARK: InteractionDelegate

    func send(surveyResponse: SurveyResponse) {
        ApptentiveLogger.interaction.info("Enqueueing survey response.")

        self.backendQueue.async {
            self.backend.send(surveyResponse: surveyResponse)
        }
    }

    func engage(event: Event) {
        self.engage(event: event, from: nil)
    }

    func requestReview(completion: @escaping (Bool) -> Void) {
        ApptentiveLogger.interaction.info("Requesting review from SKStoreReviewController.")

        self.environment.requestReview(completion: completion)
    }

    /// Asks the system to open the specified URL.
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: Called with a value indicating whether the URL was successfully opened.
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        ApptentiveLogger.interaction.info("Attempting to open URL \(url).")

        self.environment.open(url, completion: completion)
    }

    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        self.backendQueue.async {
            self.backend.invoke(invocations, completion: completion)
        }
    }

    func recordResponse(_ answers: [Answer], for questionID: String) {
        self.backendQueue.async {
            self.backend.recordResponse(answers, for: questionID)
        }
    }

    /// Delegates the sending of a message to the backend.
    /// - Parameter message: The message to be sent.
    func sendMessage(_ message: Message) {
        self.backendQueue.async {
            self.backend.sendMessage(message)
        }
    }
    /// Receives the message manager from the backend.
    /// - Parameter completion: A completion handler to be called when the message center view model is initialized.
    func getMessages(completion: @escaping (MessageManager) -> Void) {
        self.backendQueue.async {
            let messageManager = self.backend.messageManager
            DispatchQueue.main.async {
                completion(messageManager)
            }
        }
    }

    var messageCenterInForeground: Bool = false {
        didSet {
            self.backendQueue.async {
                self.backend.messageCenterInForeground = self.messageCenterInForeground
            }
        }
    }

    // MARK: EnvironmentDelegate

    func protectedDataDidBecomeAvailable(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            do {
                let containerURL = try environment.applicationSupportURL().appendingPathComponent(self.containerDirectory)

                try self.backend.protectedDataDidBecomeAvailable(containerURL: containerURL, environment: environment)

                self.person.merge(with: self.backend.conversation.person)
                self.device.merge(with: self.backend.conversation.device)
            } catch let error {
                ApptentiveLogger.default.error("Unable to access container (\(self.containerDirectory)) in Application Support directory: \(error).")
                assertionFailure("Unable to access container (\(self.containerDirectory)) in Application Support directory: \(error)")
            }
        }
    }

    func protectedDataWillBecomeUnavailable(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            self.backend.protectedDataWillBecomeUnavailable()
        }
    }

    func applicationWillEnterForeground(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            self.backend.willEnterForeground(environment: environment)
        }

        self.engage(event: .launch())
    }

    func applicationDidEnterBackground(_ environment: GlobalEnvironment) {
        self.engage(event: .exit())

        self.backendQueue.async {
            self.backend.didEnterBackground(environment: environment)
        }
    }

    func applicationWillTerminate(_ environment: GlobalEnvironment) {
        if environment.isInForeground {
            self.engage(event: .exit())
        }
    }

    // MARK: - Private

    /// Shadow of the conversation's `person` property, but accessible on the main thread.
    private var person: Person

    /// Shadow of the conversation's `device` property, but accessible on the main thread.
    private var device: Device

    /// Sync changes from the local `person` property to the conversation.
    private func updateConversationPerson() {
        self.backendQueue.async {
            self.backend.conversation.person = self.person
        }
    }

    /// Sync changes from the local `device` property to the conversation.
    private func updateConversationDevice() {
        self.backendQueue.async {
            self.backend.conversation.device = self.device
        }
    }
}

enum ApptentiveError: Error {
    case internalInconsistency
    case invalidCustomDataType(Any?)
    case fileExistsAtContainerDirectoryPath
    case mismatchedCredentials
}
