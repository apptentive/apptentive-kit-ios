//
//  Apptentive.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Describes an object that responds to authentication failures for logged-in conversations.
@objc public protocol ApptentiveDelegate: AnyObject {

    /// Indicates that an API request failed due to invalid or expired credentials.
    func authenticationDidFail(with error: Swift.Error)
}

/// The main interface to the Apptentive SDK.
public class Apptentive: NSObject, EnvironmentDelegate, InteractionDelegate, MessageManagerApptentiveDelegate, BackendDelegate {

    /// The shared instance of the Apptentive SDK.
    ///
    /// This object is created lazily upon access.
    @objc public static let shared = Apptentive()

    /// An object that responds to authentication failures for logged-in conversations.
    @objc public weak var delegate: ApptentiveDelegate?

    /// An object that overrides the `InteractionPresenter` class used to display interactions to the user.
    public var interactionPresenter: InteractionPresenter {
        didSet {
            self.interactionPresenter.delegate = self
        }
    }

    /// The theme to apply to Apptentive UI.
    ///
    /// This property must be set before calling `register(credentials:)`.
    public var theme: UITheme = .apptentive

    /// The name of the person using the app, if available.
    @objc public var personName: String? {
        get {
            var personName: String?

            self.backendQueue.sync {
                personName = self.backend.conversation?.person.name
            }

            return personName
        }
        set {
            let personName = newValue

            ApptentiveLogger.default.debug("Setting person name to “\(personName)”.")

            self.backendQueue.async {
                self.backend.conversation?.person.name = personName
            }
        }
    }

    /// The email address of the person using the app, if available.
    @objc public var personEmailAddress: String? {
        get {
            var personEmailAddress: String?

            self.backendQueue.sync {
                personEmailAddress = self.backend.conversation?.person.emailAddress
            }

            return personEmailAddress
        }
        set {
            let personEmailAddress = newValue

            ApptentiveLogger.default.debug("Setting person email address to “\(personEmailAddress)”.")

            self.backendQueue.async {
                self.backend.conversation?.person.emailAddress = personEmailAddress
            }
        }
    }

    /// The string used by the mParticle integration to identify the current user.
    @objc public var mParticleID: String? {
        get {
            var mParticleID: String?

            self.backendQueue.sync {
                mParticleID = self.backend.conversation?.person.mParticleID
            }

            return mParticleID
        }
        set {
            let mParticleID = newValue

            ApptentiveLogger.default.debug("Setting person mParticle ID to “\(mParticleID)”.")

            self.backendQueue.async {
                self.backend.conversation?.person.mParticleID = mParticleID
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
                personCustomData = self.backend.conversation?.person.customData ?? CustomData()
            }

            return personCustomData
        }
        set {
            let personCustomData = newValue

            ApptentiveLogger.default.debug("Setting person custom data to \(String(describing: personCustomData)).")

            self.backendQueue.async {
                self.backend.conversation?.person.customData = personCustomData
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
                deviceCustomData = self.backend.conversation?.device.customData ?? CustomData()
            }

            return deviceCustomData
        }
        set {
            let deviceCustomData = newValue

            ApptentiveLogger.default.debug("Setting device custom data to \(String(describing: deviceCustomData)).")

            self.backendQueue.async {
                self.backend.conversation?.device.customData = deviceCustomData
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
                result = self.backend.conversation?.appRelease.sdkDistributionName
            }

            return result
        }
        set {
            self.backendQueue.async {
                self.backend.conversation?.appRelease.sdkDistributionName = newValue
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
                result = self.backend.conversation?.appRelease.sdkDistributionVersion?.versionString
            }

            return result
        }
        set {
            self.backendQueue.async {
                self.backend.conversation?.appRelease.sdkDistributionVersion = newValue.flatMap { Version(string: $0) }
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
            DispatchQueue.main.async {
                self.applyApptentiveTheme()
            }
        } else {
            self.environment.isOverridingStyles = true
        }

        if !self.environment.isTesting {
            if credentials.key.isEmpty || credentials.signature.isEmpty {
                apptentiveCriticalError("App key or signature is missing.")
            } else if !credentials.key.hasPrefix("IOS-") {
                apptentiveCriticalError("Invalid app key. Please check the dashboard for the correct app key.")
            }
        }

        self.backendQueue.async {
            self.backend.register(appCredentials: credentials, environment: self.environment) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let connectionType):
                        completion?(.success(()))
                        ApptentiveLogger.default.info("Apptentive SDK registered successfully (\(connectionType == .new ? "new" : "existing") conversation).")

                    case .failure(let error):
                        completion?(.failure(error))
                        ApptentiveLogger.default.error("Failed to register Apptentive SDK: \(error)")
                        if !self.environment.isTesting {
                            apptentiveCriticalError("Failed to register Apptentive SDK: Please double-check that the app key, signature, and the url is correct.")
                        }
                    }
                }
            }
        }
    }

    /// Provides the SDK with the credentials necessary to connect to the Apptentive API.
    /// - Parameter credentials: The `AppCredentials` object containing your Apptentive key and signature.
    /// - Throws: An error if registration fails.
    @available(iOS 13.0.0, *)
    public func register(with credentials: AppCredentials) async throws {
        let _ = try await withCheckedThrowingContinuation { continuation in
            self.register(with: credentials) { continuation.resume(returning: $0) }
        }
    }

    /// Contains the app-level credentials necessary to connect to the Apptentive API.
    public struct AppCredentials: Codable, Equatable {

        /// The Apptentive App Key (found in the API & Development section of the Settings tab in the Apptentive Dashboard).
        public let key: String

        /// The Apptentive App Signature (found in the API & Development section of the Settings tab in the Apptentive Dashboard).
        public let signature: String

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
            self.backend.engage(event: event) { result in
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(result)
                    }
                } else {
                    if case .failure(let error) = result {
                        ApptentiveLogger.default.error("Error when engaging event: \(error)")
                    }
                }
            }
        }
    }

    /// Engages the specified event, using the view controller (if any) as the presenting view controller for any interactions.
    /// - Parameters:
    ///   - event: The event to engage.
    ///   - viewController: The view controller from which any interactions triggered by this (or future) event(s) should be presented.
    /// - Returns: A boolean indicating whether or not an interaction was presented.
    /// - Throws: An error if engaging the event fails.
    @available(iOS 13.0.0, *)
    public func engage(event: Event, from viewController: UIViewController? = nil) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.engage(event: event, from: viewController) { continuation.resume(with: $0) }
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
        self.canShowMessageCenter { result in
            if case .success(let canShow) = result, canShow {
                self.engage(event: .showMessageCenter, from: viewController, completion: completion)
            } else {
                self.engage(event: .showMessageCenterFallback, from: viewController, completion: completion)
            }
        }
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

    /// Presents Apptentive's Message Center using the specified view controller for presentation,
    /// attaching the specified custom data to the first message (if any) sent by the user.
    /// - Parameters:
    ///   - viewController: The view controller from which to present Message Center.
    ///   - customData: The custom data to send along with the message.
    /// - Returns: A boolean indicating if the message center was presented.
    /// - Throws: An error if presenting message center with custom data fails.
    @available(iOS 13.0.0, *)
    public func presentMessageCenter(from viewController: UIViewController?, with customData: CustomData? = nil) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            if let customData = customData {
                self.presentMessageCenter(from: viewController, with: customData) { continuation.resume(with: $0) }
            } else {
                self.presentMessageCenterCompat(from: viewController)
            }
        }
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
            return apptentiveCriticalError("Unable to convert image to JPEG data.")
        }

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "image.jpeg", storage: .inMemory(imageData))
        self.sendMessage(.init(nonce: "hidden", attachments: [attachment], isHidden: true))
    }

    /// Sends the specified data attached to a hidden message to the app's dashboard.
    /// - Parameters:
    ///   - fileData: The contents of the file.
    ///   - mediaType: The media type for the file.
    @objc(sendAttachmentFile:withMimeType:)
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
            self.backend.canShowInteraction(event: event) { result in
                if let completion = completion {
                    DispatchQueue.main.async {
                        completion(result)
                    }
                } else {
                    if case .failure(let error) = result {
                        ApptentiveLogger.default.error("Error when evaluating criteria: \(error)")
                    }
                }
            }
        }
    }

    /// Checks if the event can trigger an interaction.
    /// - Parameter event: The event used to check if it can trigger an interaction.
    /// - Returns: A boolean indicating whether or not an interaction can be shown using the event.
    /// - Throws: An error when failing.
    @available(iOS 13.0.0, *)
    public func canShowInteraction(event: Event) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.canShowInteraction(event: event) { continuation.resume(with: $0) }
        }
    }

    /// Checks if Message Center can be presented.
    /// - Parameter completion: A completion handler that is called with a boolean indicating whether or not an interaction can be shown using the event.
    public func canShowMessageCenter(completion: ((Result<Bool, Error>) -> Void)? = nil) {
        self.canShowInteraction(event: .showMessageCenter, completion: completion)
    }

    /// Checks if Message Center can be presented.
    /// - Returns: A boolean indicating whether or not an interaction can be shown using the event.
    /// - Throws: An error when failing.
    @available(iOS 13.0.0, *)
    public func canShowMessageCenter() async throws -> Bool {
        return try await self.canShowInteraction(event: .showMessageCenter)
    }

    /// Uses the specified JWT to authenticate a conversation.
    ///
    /// This also encrypts the conversation data stored on the device.
    ///
    /// The first call to this method on a given app install will upgrade the
    /// initial conversation to an authenticated/encrypted conversation.
    ///
    /// Before calling this method again, `logOut()` must be called.
    ///
    /// After logging out, subsequent calls to this method will either resume
    /// a conversation that was previously logged out (based on the `sub`
    /// claim in the JWT), or create a new conversation for a subject that
    /// has not previously logged in.
    /// - Parameters:
    ///   - token: The JWT used to authenticate the conversation.
    ///   The JWT's `sub` (subject) claim is used to identify the conversation
    ///   when logging back in from a logged-out state. The JWT should be
    ///   signed with the secret from the API & Development section of the
    ///   Settings tab in your app's Apptentive dashboard.
    ///   - completion: A completion handler that is called with the result  of the login operation.
    public func logIn(with token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            self.backend.logIn(with: token) { result in
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    /// Uses the specified JWT to authenticate a conversation.
    ///
    /// This also encrypts the conversation data stored on the device.
    ///
    /// The first call to this method on a given app install will upgrade the
    /// initial conversation to an authenticated/encrypted conversation.
    ///
    /// Before calling this method again, `logOut()` must be called.
    ///
    /// After logging out, subsequent calls to this method will either resume
    /// a conversation that was previously logged out (based on the `sub`
    /// claim in the JWT), or create a new conversation for a subject that
    /// has not previously logged in.
    /// - Parameter token: The JWT used to authenticate the conversation.
    ///   The JWT's `sub` (subject) claim is used to identify the conversation
    ///   when logging back in from a logged-out state. The JWT should be
    ///   signed with the secret from the API & Development section of the
    ///   Settings tab in your app's Apptentive dashboard.
    /// - Throws: an error if there is a problem logging in.
    @available(iOS 13.0.0, *)
    public func logIn(with token: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.logIn(with: token) { continuation.resume(with: $0) }
        }
    }

    /// Logs out the active conversation.
    ///
    /// This also discards the key used to encrypt/decrypt the conversation data and deletes cached attachments.
    /// - Parameter completion: A completion handler that is called with the result of the logout operation.
    public func logOut(completion: ((Result<Void, Error>) -> Void)?) {
        self.backendQueue.async {
            do {
                try self.backend.logOut()
                DispatchQueue.main.async {
                    completion?(.success(()))
                }
            } catch let error {
                if let completion = completion {
                    completion(.failure(error))
                } else {
                    ApptentiveLogger.default.error("Error when logging out: \(error).")
                }
            }
        }
    }

    /// Logs out the active conversation.
    ///
    /// This also discards the key used to encrypt/decrypt the conversation data and deletes cached attachments.
    /// - Throws: an error if the logout operation fails.
    @available(iOS 13.0.0, *)
    public func logOut() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.logOut { continuation.resume(with: $0) }
        }
    }

    /// Updates the JWT for the currently logged-in conversation.
    /// - Parameters:
    ///   - token: The new JWT.
    ///   - completion: A completion handler that is called with the result of the update operation.
    public func updateToken(_ token: String, completion: ((Result<Void, Error>) -> Void)? = nil) {
        self.backendQueue.async {
            self.backend.updateToken(token) { result in
                DispatchQueue.main.async {
                    completion?(result)
                }
            }
        }
    }

    /// Updates the JWT for the currently logged-in conversation.
    /// - Parameter token: The new JWT.
    /// - Throws: an error if the update operation fails.
    @available(iOS 13.0.0, *)
    public func updateToken(_ token: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.updateToken(token) { continuation.resume(with: $0) }
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

    init(baseURL: URL? = nil, containerDirectory: String? = nil, backendQueue: DispatchQueue? = nil, environment: GlobalEnvironment? = nil) {
        if Self.alreadyInitialized {
            apptentiveCriticalError("Attempting to instantiate an Apptentive object but an instance already exists.")
        }

        Self.alreadyInitialized = true

        // swift-format-ignore
        self.baseURL = baseURL ?? URL(string: "https://api.apptentive.com/")!
        self.backendQueue = backendQueue ?? DispatchQueue(label: "com.apptentive.backend", qos: .default, autoreleaseFrequency: .workItem)
        self.environment = environment ?? Environment()
        let containerName = containerDirectory ?? "com.apptentive.feedback"
        self.backend = Backend(queue: self.backendQueue, environment: self.environment, baseURL: self.baseURL, containerName: containerName)

        self.interactionPresenter = InteractionPresenter()

        super.init()

        self.environment.delegate = self
        self.backend.delegate = self
        self.interactionPresenter.delegate = self
        self.backend.messageManager.messageManagerApptentiveDelegate = self

        if self.environment.isInForeground {
            self.applicationWillEnterForeground(self.environment)
        }

        if self.environment.isProtectedDataAvailable {
            self.protectedDataDidBecomeAvailable(self.environment)
        }

        ApptentiveLogger.default.info("Apptentive SDK Version \(self.environment.sdkVersion.versionString) Initialized.")
    }

    static var alreadyInitialized = false

    // MARK: EnvironmentDelegate

    func protectedDataDidBecomeAvailable(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable(environment: environment)
            } catch let error {
                ApptentiveLogger.default.error("Unable to start Backend: \(error).")
                apptentiveCriticalError("Unable to start Backend: \(error)")
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
    }

    func applicationDidEnterBackground(_ environment: GlobalEnvironment) {
        self.backendQueue.async {
            self.backend.didEnterBackground(environment: environment)
        }
    }

    func applicationWillTerminate(_ environment: GlobalEnvironment) {
        if environment.isInForeground {
            self.engage(event: .exit())
        }
    }

    func authenticationDidFail(with error: Swift.Error) {
        self.delegate?.authenticationDidFail(with: error)
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

public enum ApptentiveError: Swift.Error, LocalizedError {
    case internalInconsistency
    case invalidCustomDataType(Any?)
    case fileExistsAtContainerDirectoryPath
    case unsupportedBackendStateTransition
    case emptyEventName
    case notLoggedIn
    case alreadyLoggedIn(subject: String, id: String)
    case loginCalledBeforeRegister
    case activeConversationPending
    case missingSubClaim
    case mismatchedSubClaim
    case invalidEncryptionKey
    case noActiveConversation
    case authenticationFailed(reason: AuthenticationFailureReason?, responseString: String?)

    // swift-format-ignore
    public var errorDescription: String? {
        switch self {
        case .internalInconsistency:
            return "Internal error."

        case .invalidCustomDataType(let value):
            return "Unsupported type for custom data: \(String(describing: value))"

        case .fileExistsAtContainerDirectoryPath:
            return "Internal error: creation of Apptentive container directory failed because a file was present at that path."

        case .unsupportedBackendStateTransition:
            return "Internal error: the SDK state transitioned between unexpected states."

        case .notLoggedIn:
            return "Attempting to log out without being logged in."

        case .alreadyLoggedIn(let subject, let id):
            return "Attempting to log in when already logged in (subject: \(subject), id: \(id))."

        case .loginCalledBeforeRegister:
            return "Attempting to log in before registering the SDK."

        case .activeConversationPending:
            return "Attempting to log in before the SDK has connected to the API."

        case .missingSubClaim:
            return "The JWT passed to logIn(with:completion:) was missing its sub (subject) claim."

        case .mismatchedSubClaim:
            return "The subject claimed by the JWT passed to updateToken(_:completion:) did not match the logged-in conversation."

        case .invalidEncryptionKey:
            return "Internal error: The encryption key received from the API could not be decoded."

        case .noActiveConversation:
            return "The SDK is currently logged out."

        case .authenticationFailed(let reason, responseString: _):
            return "An API request failed due to an invalid JWT (\(reason?.description ?? "Unknown Error")). Please call updateToken(_:completion:) with a new JWT."

        case .emptyEventName:
            return "An event must have a non-empty name."
        }
    }
}

public enum AuthenticationFailureReason: String, Codable {
    case invalidAlgorithm = "INVALID_ALGORITHM"
    case malformedToken = "MALFORMED_TOKEN"
    case invalidToken = "INVALID_TOKEN"
    case missingSubClaim = "MISSING_SUB_CLAIM"
    case mismatchedSubClaim = "MISMATCHED_SUB_CLAIM"
    case invalidSubClaim = "INVALID_SUB_CLAIM"
    case expiredToken = "EXPIRED_TOKEN"
    case revokedToken = "REVOKED_TOKEN"
    case missingAppKey = "MISSING_APP_KEY"
    case missingAppSignature = "MISSING_APP_SIGNATURE"
    case invalidKeySignaturePair = "INVALID_KEY_SIGNATURE_PAIR"

    var description: String {
        switch self {
        case .invalidAlgorithm:
            return "Invalid Algorithm"
        case .malformedToken:
            return "Malformed Token"
        case .invalidToken:
            return "Invalid Token"
        case .missingSubClaim:
            return "Missing Sub Claim"
        case .mismatchedSubClaim:
            return "Mismatched Sub Claim"
        case .invalidSubClaim:
            return "Invalid Sub Claim"
        case .expiredToken:
            return "Expired Token"
        case .revokedToken:
            return "Revoked Token"
        case .missingAppKey:
            return "Missing App Key"
        case .missingAppSignature:
            return "Missing App Signature"
        case .invalidKeySignaturePair:
            return "Invalid Key/Signature Pair"
        }
    }
}

/// The method to call when a critical error occurs.
///
/// This can be overriden, for example:
/// ```
/// apptentiveAssertionHandler = { message, file, line in
///     print("\(file):\(line): Apptentive critical error: \(message())")
/// }
/// ```
public var apptentiveAssertionHandler = { (message: @autoclosure () -> String, file, line) in
    assertionFailure(message(), file: file, line: line)
}

func apptentiveCriticalError(_ message: String, file: StaticString = #file, line: UInt = #line) {
    apptentiveAssertionHandler(message, file, line)
}
