import AuthenticationServices
import BitwardenKit
import Combine
import UIKit

// MARK: - CreatePasskeyProcessor

/// The processor for the create passkey test screen.
///
@available(iOS 17, *)
class CreatePasskeyProcessor: StateProcessor<
    CreatePasskeyState,
    CreatePasskeyAction,
    CreatePasskeyEffect,
> {
    // MARK: Types

    typealias PerformRegistration = (
        _ rpId: String,
        _ userName: String,
        _ displayName: String,
        _ presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws -> Void

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// A delegate used to obtain a presentation anchor for the passkey sheet.
    private weak var delegate: CreatePasskeyProcessorDelegate?

    // MARK: Internal for Testability

    /// Performs the passkey registration flow. Injected for testability.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier.
    ///   - userName: The username for the credential.
    ///   - displayName: The display name for the credential.
    ///   - presentationAnchor: Provides the window used to present the passkey sheet.
    let performRegistration: PerformRegistration

    // MARK: Initialization

    /// Initializes a `CreatePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate used to obtain the presentation anchor.
    ///   - performRegistration: Performs the passkey registration flow. Defaults to the real
    ///     `ASAuthorizationController`-based implementation; overridable in tests.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: CreatePasskeyProcessorDelegate?,
        performRegistration: @escaping PerformRegistration = CreatePasskeyProcessor.performPasskeyRegistration,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.performRegistration = performRegistration
        super.init(state: CreatePasskeyState())
    }

    // MARK: Static Methods

    /// The real passkey registration implementation using `ASAuthorizationController`.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier.
    ///   - userName: The username for the credential.
    ///   - displayName: The display name for the credential.
    ///   - presentationAnchor: Provides the window used to present the passkey sheet.
    ///
    private static func performPasskeyRegistration(
        rpId: String,
        userName: String,
        displayName: String,
        presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws {
        let window = await presentationAnchor()

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let userId = Data(UUID().uuidString.utf8)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userName,
            userID: userId,
        )
        request.displayName = displayName.isEmpty ? userName : displayName

        try await PasskeyRegistrationCoordinator(window: window).register(request: request)
    }

    // MARK: Methods

    override func receive(_ action: CreatePasskeyAction) {
        switch action {
        case let .displayNameChanged(newValue):
            state.displayName = newValue
            state.status = .idle
        case let .rpIdChanged(newValue):
            state.rpId = newValue
            state.status = .idle
        case let .userNameChanged(newValue):
            state.userName = newValue
            state.status = .idle
        }
    }

    override func perform(_ effect: CreatePasskeyEffect) async {
        switch effect {
        case .registerPasskey:
            await registerPasskey()
        }
    }

    // MARK: Private

    /// Orchestrates state transitions and calls `performRegistration`.
    private func registerPasskey() async {
        state.status = .inProgress
        do {
            try await performRegistration(state.rpId, state.userName, state.displayName) { [weak self] in
                await self?.delegate?.presentationAnchorForPasskeyRegistration() ?? UIWindow()
            }
            state.status = .success
        } catch let error as ASAuthorizationError where error.code == .canceled {
            state.status = .idle
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}

// MARK: - CreatePasskeyProcessorDelegate

/// A delegate that provides a presentation anchor for the passkey registration sheet.
///
protocol CreatePasskeyProcessorDelegate: AnyObject {
    /// Returns the window used to present the passkey sheet.
    @MainActor
    func presentationAnchorForPasskeyRegistration() async -> ASPresentationAnchor
}

// MARK: - PasskeyRegistrationError

/// Errors that can occur during passkey registration.
///
enum PasskeyRegistrationError: Error, LocalizedError {
    /// The credential returned by the authorization controller was not the expected type.
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .unexpectedCredentialType:
            Localizations.unexpectedCredentialTypeReceived
        }
    }
}

// MARK: - PasskeyRegistrationCoordinator

/// Drives an `ASAuthorizationController` request and bridges its delegate callbacks to a Swift
/// concurrency continuation. Since the controller's `delegate` and `presentationContextProvider`
/// are weak references, this object owns the continuation itself so that calling `register(request:)`
/// as an async instance method keeps it alive (via the caller's `await`) for the life of the request,
/// without needing `objc_setAssociatedObject` to retain a separate delegate object.
///
@available(iOS 17, *)
private class PasskeyRegistrationCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    // MARK: Private Properties

    private var continuation: CheckedContinuation<Void, Error>?
    private let window: ASPresentationAnchor

    // MARK: Initialization

    init(window: ASPresentationAnchor) {
        self.window = window
    }

    // MARK: Methods

    /// Performs the authorization request and suspends until the delegate receives a result.
    ///
    /// - Parameter request: The credential registration request to perform.
    ///
    func register(request: ASAuthorizationRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: ASAuthorizationControllerDelegate

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization,
    ) {
        defer { continuation = nil }
        guard authorization.credential is ASAuthorizationPublicKeyCredentialRegistration else {
            continuation?.resume(throwing: PasskeyRegistrationError.unexpectedCredentialType)
            return
        }
        continuation?.resume()
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error,
    ) {
        defer { continuation = nil }
        continuation?.resume(throwing: error)
    }

    // MARK: ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}
