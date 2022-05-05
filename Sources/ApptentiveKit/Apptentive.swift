//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The main interface to the Apptentive SDK.
public class Apptentive: NSObject, EnvironmentDelegate, InteractionDelegate, MessageManagerApptentiveDelegate {

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

    /// The name of the person using the app, if available.
    @objc public var personName: String? {
        get {
            var personName: String?

            self.backendQueue.sync {
                personName = self.backend.conversation.person.name
            }

            return personName
        }
        set {
            let personName = newValue

            ApptentiveLogger.default.debug("Setting person name to “\(personName)”.")

            self.backendQueue.async {
                self.backend.conversation.person.name = personName
            }
        }
    }

    /// The email address of the person using the app, if available.
    @objc public var personEmailAddress: String? {
        get {
            var personEmailAddress: String?

            self.backendQueue.sync {
                personEmailAddress = self.backend.conversation.person.emailAddress
            }

            return personEmailAddress
        }
        set {
            let personEmailAddress = newValue

            ApptentiveLogger.default.debug("Setting person email address to “\(personEmailAddress)”.")

            self.backendQueue.async {
                self.backend.conversation.person.emailAddress = personEmailAddress
            }
        }
    }

    /// The string used by the mParticle integration to identify the current user.
    @objc public var mParticleID: String? {
        get {
            var mParticleID: String?

            self.backendQueue.sync {
                mParticleID = self.backend.conversation.person.mParticleID
            }

            return mParticleID
        }
        set {
            let mParticleID = newValue

            ApptentiveLogger.default.debug("Setting person mParticle ID to “\(mParticleID)”.")

            self.backendQueue.async {
                self.backend.conversation.person.mParticleID = mParticleID
            }
        }
    }

    /// The custom data assocated with the person using the app.
    ///
    /// Supported types are `String`, `Bool`, and numbers.
    public var personCustomData: CustomData {
        get {
            var personCustomData = CustomData()

            self.backendQueue.sync {
                personCustomData = self.backend.conversation.person.customData
            }

            return personCustomData
        }
        set {
            let personCustomData = newValue

            ApptentiveLogger.default.debug("Setting person custom data to \(String(describing: personCustomData)).")

            self.backendQueue.async {
                self.backend.conversation.person.customData = personCustomData
            }
        }
    }

    /// The custom data associated with the device running the app.
    ///
    /// Supported types are `String`, `Bool`, and numbers.
    public var deviceCustomData: CustomData {
        get {
            var deviceCustomData = CustomData()

            self.backendQueue.sync {
                deviceCustomData = self.backend.conversation.device.customData
            }

            return deviceCustomData
        }
        set {
            let deviceCustomData = newValue

            ApptentiveLogger.default.debug("Setting device custom data to \(String(describing: deviceCustomData)).")

            self.backendQueue.async {
                self.backend.conversation.device.customData = deviceCustomData
            }
        }
    }

    /// The number of unread messages in message center.
    @objc dynamic public var unreadMessageCount = 0

    /// The name of the distribution method for this SDK instance (not for app use).
    ///
    /// This property is used to track the relative popularity of various methods of
    /// integrating this SDK, for example "React Native" or "CocoaPods".
    ///
    /// This property is not intended to be set by apps using the SDK, but
    /// should be set by projects that re-package the SDK for distribution
    /// as part of e.g. a cross-platform app framework.
    @objc public var distributionName: String? {
        get {
            var result: String?

            self.backendQueue.sync {
                result = self.backend.conversation.appRelease.sdkDistributionName
            }

            return result
        }
        set {
            self.backendQueue.async {
                self.backend.conversation.appRelease.sdkDistributionName = newValue
            }
        }
    }

    /// The version of the distribution for this SDK instance (not for app use).
    ///
    /// This property is used to track the version of any projects
    /// that re-package the SDK as part of e.g. a cross-platform app-
    /// development framework.
    ///
    /// This property is not intended to be set by apps using the SDK.
    @objc public var distributionVersion: String? {
        get {
            var result: String?

            self.backendQueue.sync {
                result = self.backend.conversation.appRelease.sdkDistributionVersion?.versionString
            }

            return result
        }
        set {
            self.backendQueue.async {
                self.backend.conversation.appRelease.sdkDistributionVersion = newValue.flatMap { Version(string: $0) }
            }
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
    public func register(with credentials: AppCredentials, completion: ((Result<Void, Error>) -> Void)? = nil) {
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
            self.backend.register(appCredentials: credentials) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let connectionType):
                        completion?(.success(()))
                        ApptentiveLogger.default.info("Apptentive SDK registered successfully (\(connectionType == .new ? "new" : "existing") conversation).")

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

        NotificationCenter.default.post(name: Notification.Name.apptentiveEventEngaged, object: nil, userInfo: event.userInfoForNotification())

        self.backendQueue.async {
            self.backend.engage(event: event, completion: completion)
        }
    }

    /// Dimisses any currently-visible interactions.
    ///
    /// Note that it is not possible to programmatically dismiss the Apple Rating Dialog (`SKStoreReviewController`).
    /// - Parameter animated: Whether to animate the dismissal.
    public func dismissAllInteractions(animated: Bool) {
        self.interactionPresenter.dismissPresentedViewController(animated: animated)
    }

    // MARK: Message Center

    /// Presents Apptentive's Message Center using the specified view controller for presentation.
    /// - Parameters:
    ///   - viewController: The view controller from which to present Message Center.
    ///   - completion: Called with the result of the message center presentation request.
    public func presentMessageCenter(from viewController: UIViewController?, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        self.engage(event: .showMessageCenter, from: viewController, completion: completion)
    }

    /// Presents Apptentive's Message Center using the specified view controller for presentation,
    /// attaching the specified custom data to the first message (if any) sent by the user.
    /// - Parameters:
    ///   - viewController: The view controller from which to present Message Center.
    ///   - customData: The custom data to send along with the message.
    ///   - completion: Called with the result of the message center presentation request.
    public func presentMessageCenter(from viewController: UIViewController?, with customData: CustomData?, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        if let customData = customData {
            self.backendQueue.async {
                self.backend.messageManager.customData = customData
            }
        }

        self.presentMessageCenter(from: viewController, completion: completion)
    }

    /// Sends the specified text as a hidden message to the app's dashboard.
    /// - Parameter text: The text to send in the body of the message.
    @objc(sendAttachmentText:)
    public func sendAttachment(_ text: String) {
        self.sendMessage(MessageList.Message(nonce: "hidden", body: text, attachments: [], sentDate: Date(), isHidden: true))
    }

    /// Sends the specified image (encoded as a JPEG at 95% quality) attached to a hidden message to the app's dashboard.
    /// - Parameter image: The image to encode and send.
    @objc(sendAttachmentImage:)
    public func sendAttachment(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.95) else {
            return assertionFailure("Unable to convert image to JPEG data.")
        }

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "image.jpeg", storage: .inMemory(imageData))
        self.sendMessage(.init(nonce: "hidden", attachments: [attachment], isHidden: true))
    }

    /// Sends the specified data attached to a hidden message to the app's dashboard.
    /// - Parameters:
    ///   - fileData: The contents of the file.
    ///   - mediaType: The media type for the file.
    @objc(sendAttachmentData:mimeType:)
    public func sendAttachment(_ fileData: Data, mediaType: String) {
        var filename = "file"

        if let pathExtension = AttachmentManager.pathExtension(for: mediaType) {
            filename.append(".\([pathExtension])")
        }

        let attachment = MessageList.Message.Attachment(contentType: mediaType, filename: filename, storage: .inMemory(fileData))
        self.sendMessage(.init(nonce: "hidden", attachments: [attachment], isHidden: true))
    }

    /// Checks if the event can trigger an interaction.
    /// - Parameters:
    ///  - event: The event used to check if it can trigger an interaction.
    ///  - completion: A completion handler that is called with a boolean indicating whether or not an interaction can be shown using the event.
    public func canShowInteraction(event: Event, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        self.backendQueue.async {
            self.backend.canShowInteraction(event: event, completion: completion)
        }
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

        super.init()

        self.environment.delegate = self
        self.backend.frontend = self
        self.interactionPresenter.delegate = self
        self.backend.messageManager.messageManagerApptentiveDelegate = self

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
                self.backend.messageManager.forceMessageDownload = true
            }
        }

        ApptentiveLogger.default.info("Apptentive SDK Version \(self.environment.sdkVersion.versionString) Initialized.")
    }

    static var alreadyInitialized = false

    // MARK: EnvironmentDelegate

    func protectedDataDidBecomeAvailable(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            do {
                let containerURL = try environment.applicationSupportURL().appendingPathComponent(self.containerDirectory)
                let cachesURL = try environment.cachesURL().appendingPathComponent(self.containerDirectory)

                try self.backend.protectedDataDidBecomeAvailable(containerURL: containerURL, cachesURL: cachesURL, environment: environment)
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

    private func sendMessage(_ message: MessageList.Message) {
        self.backendQueue.async {
            do {
                try self.backend.sendMessage(message)
            } catch let error {
                ApptentiveLogger.default.error("Error sending message: \(error)")
            }
        }
    }
}

public enum ApptentiveError: Error {
    case internalInconsistency
    case invalidCustomDataType(Any?)
    case fileExistsAtContainerDirectoryPath
    case mismatchedCredentials
}
