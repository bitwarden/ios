import AuthenticationServices
import BitwardenKit
import Combine
import UIKit

// MARK: - CreatePasskeyProcessor

/// The processor for the create passkey test screen.
///
class CreatePasskeyProcessor: StateProcessor<
    CreatePasskeyState,
    CreatePasskeyAction,
    CreatePasskeyEffect,
> {
    // MARK: Types

    typealias PerformRegistration = (_ rpId: String, _ userName: String, _ displayName: String) async throws -> Void

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// A delegate used to obtain a presentation anchor for the passkey sheet.
    private weak var delegate: CreatePasskeyProcessorDelegate?

    // MARK: Internal for Testability

    /// Performs the passkey registration flow. Overridable in tests.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier.
    ///   - userName: The username for the credential.
    ///   - displayName: The display name for the credential.
    var performRegistration: PerformRegistration

    // MARK: Initialization

    /// Initializes a `CreatePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate used to obtain the presentation anchor.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: CreatePasskeyProcessorDelegate?,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        performRegistration = { _, _, _ in throw PasskeyRegistrationError.notAvailable }
        super.init(state: CreatePasskeyState())

        performRegistration = { [weak self] rpId, userName, displayName in
            try await self?.performPasskeyRegistration(
                rpId: rpId,
                userName: userName,
                displayName: displayName,
            )
        }
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
            try await performRegistration(state.rpId, state.userName, state.displayName)
            state.status = .success
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }

    /// The real passkey registration implementation using `ASAuthorizationController`.
    private func performPasskeyRegistration(
        rpId: String,
        userName: String,
        displayName: String,
    ) async throws {
        guard #available(iOS 17, *) else {
            throw PasskeyRegistrationError.notAvailable
        }

        let window = await delegate?.presentationAnchorForPasskeyRegistration() ?? UIWindow()

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let userId = Data(UUID().uuidString.utf8)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userName,
            userID: userId,
        )
        request.displayName = displayName.isEmpty ? userName : displayName

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let handler = PasskeyRegistrationHandler(continuation: continuation, window: window)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = handler
            controller.presentationContextProvider = handler
            // Retain the handler for the lifetime of the controller sheet.
            objc_setAssociatedObject(
                controller,
                &passkeyContinuationKey,
                handler,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC,
            )
            controller.performRequests()
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
    /// Passkey registration is not available on this OS version.
    case notAvailable

    /// The credential returned by the authorization controller was not the expected type.
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            Localizations.passkeyRegistrationRequiresIOS17OrLater
        case .unexpectedCredentialType:
            Localizations.unexpectedCredentialTypeReceived
        }
    }
}

// MARK: - PasskeyRegistrationHandler

/// Bridges `ASAuthorizationControllerDelegate` callbacks to a Swift concurrency continuation.
///
@available(iOS 17, *)
private class PasskeyRegistrationHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    // MARK: Private Properties

    private let continuation: CheckedContinuation<Void, Error>
    private let window: ASPresentationAnchor

    // MARK: Initialization

    init(continuation: CheckedContinuation<Void, Error>, window: ASPresentationAnchor) {
        self.continuation = continuation
        self.window = window
    }

    // MARK: ASAuthorizationControllerDelegate

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization,
    ) {
        guard authorization.credential is ASAuthorizationPublicKeyCredentialRegistration else {
            continuation.resume(throwing: PasskeyRegistrationError.unexpectedCredentialType)
            return
        }
        continuation.resume()
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithError error: Error,
    ) {
        continuation.resume(throwing: error)
    }

    // MARK: ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}

// MARK: - Private Globals

/// Key for the `objc_setAssociatedObject` used to retain `PasskeyRegistrationHandler`.
private var passkeyContinuationKey: UInt8 = 0
