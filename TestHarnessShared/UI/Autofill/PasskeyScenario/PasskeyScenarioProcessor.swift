import AuthenticationServices
import BitwardenKit
import Combine
import UIKit

// MARK: - PasskeyScenarioProcessor

/// The processor for the unified passkey scenario screen.
///
class PasskeyScenarioProcessor: StateProcessor<
    PasskeyScenarioState,
    PasskeyScenarioAction,
    PasskeyScenarioEffect,
> {
    // MARK: Types

    typealias PerformAssertion = (_ rpId: String) async throws -> Void
    typealias PerformRegistration = (_ rpId: String, _ userName: String, _ displayName: String) async throws -> Void

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// A delegate used to obtain a presentation anchor for passkey sheets.
    private weak var delegate: PasskeyScenarioProcessorDelegate?

    /// The service used to persist passkey registration metadata.
    private let passkeyRegistryService: PasskeyRegistryService

    // MARK: Internal for Testability

    /// Performs the passkey assertion flow. Overridable in tests.
    var performAssertion: PerformAssertion

    /// Performs the passkey registration flow. Overridable in tests.
    var performRegistration: PerformRegistration

    // MARK: Initialization

    /// Initializes a `PasskeyScenarioProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate used to obtain presentation anchors.
    ///   - passkeyRegistryService: The service used to persist passkey registration metadata.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: PasskeyScenarioProcessorDelegate?,
        passkeyRegistryService: PasskeyRegistryService,
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.passkeyRegistryService = passkeyRegistryService
        performAssertion = { _ in throw PasskeyAssertionError.notAvailable }
        performRegistration = { _, _, _ in throw PasskeyRegistrationError.notAvailable }
        super.init(state: PasskeyScenarioState())

        performAssertion = { [weak self] rpId in
            try await self?.performPasskeyAssertion(rpId: rpId)
        }
        performRegistration = { [weak self] rpId, userName, displayName in
            try await self?.performPasskeyRegistration(
                rpId: rpId,
                userName: userName,
                displayName: displayName,
            )
        }
    }

    // MARK: Methods

    override func receive(_ action: PasskeyScenarioAction) {
        switch action {
        case let .displayNameChanged(newValue):
            state.displayName = newValue
            state.registrationStatus = .idle
        case let .modeChanged(newMode):
            state.mode = newMode
        case let .rpIdChanged(newValue):
            state.assertionStatus = .idle
            state.registrationStatus = .idle
            state.rpId = newValue
        case let .userNameChanged(newValue):
            state.registrationStatus = .idle
            state.userName = newValue
        }
    }

    override func perform(_ effect: PasskeyScenarioEffect) async {
        switch effect {
        case .assertPasskey:
            await assertPasskey()
        case .clearAll:
            await passkeyRegistryService.clearAll()
            state.passkeys = []
        case let .deletePasskey(entry):
            await passkeyRegistryService.deletePasskey(entry)
            state.passkeys = await passkeyRegistryService.loadPasskeys()
        case .loadPasskeys:
            state.passkeys = await passkeyRegistryService.loadPasskeys()
        case .registerPasskey:
            await registerPasskey()
        }
    }

    // MARK: Private

    private func assertPasskey() async {
        state.assertionStatus = .inProgress
        do {
            try await performAssertion(state.rpId)
            state.assertionStatus = .success
        } catch let error as ASAuthorizationError where error.code == .canceled {
            state.assertionStatus = .idle
        } catch {
            state.assertionStatus = .failure(error.localizedDescription)
        }
    }

    private func registerPasskey() async {
        state.registrationStatus = .inProgress
        do {
            try await performRegistration(state.rpId, state.userName, state.displayName)
            await passkeyRegistryService.savePasskey(
                PasskeyEntry(
                    id: UUID(),
                    rpId: state.rpId,
                    userName: state.userName,
                    displayName: state.displayName,
                    createdAt: Date(),
                ),
            )
            state.registrationStatus = .success
            state.passkeys = await passkeyRegistryService.loadPasskeys()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            state.registrationStatus = .idle
        } catch {
            state.registrationStatus = .failure(error.localizedDescription)
        }
    }

    private func performPasskeyAssertion(rpId: String) async throws {
        guard #available(iOS 17, *) else { throw PasskeyAssertionError.notAvailable }

        let window = await delegate?.presentationAnchorForPasskeyAssertion() ?? UIWindow()
        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = Data((0 ..< 32).map { _ in UInt8.random(in: 0 ... 255) })
        let request = provider.createCredentialAssertionRequest(challenge: challenge)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let handler = PasskeyAssertionHandler(continuation: continuation, window: window)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = handler
            controller.presentationContextProvider = handler
            objc_setAssociatedObject(
                controller,
                &passkeyAssertionContinuationKey,
                handler,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC,
            )
            controller.performRequests()
        }
    }

    private func performPasskeyRegistration(
        rpId: String,
        userName: String,
        displayName: String,
    ) async throws {
        guard #available(iOS 17, *) else { throw PasskeyRegistrationError.notAvailable }

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
            objc_setAssociatedObject(
                controller,
                &passkeyRegistrationContinuationKey,
                handler,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC,
            )
            controller.performRequests()
        }
    }
}

// MARK: - PasskeyScenarioProcessorDelegate

/// A delegate that provides presentation anchors for passkey sheets.
///
protocol PasskeyScenarioProcessorDelegate: AnyObject {
    /// Returns the window used to present the passkey assertion sheet.
    @MainActor
    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor

    /// Returns the window used to present the passkey registration sheet.
    @MainActor
    func presentationAnchorForPasskeyRegistration() async -> ASPresentationAnchor
}

// MARK: - PasskeyAssertionError

/// Errors that can occur during passkey assertion.
///
enum PasskeyAssertionError: Error, LocalizedError {
    /// Passkey assertion is not available on this OS version.
    case notAvailable

    /// The credential returned by the authorization controller was not the expected type.
    case unexpectedCredentialType

    var errorDescription: String? {
        switch self {
        case .notAvailable: Localizations.passkeyAssertionNotAvailable
        case .unexpectedCredentialType: Localizations.unexpectedCredentialTypeReceived
        }
    }
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
        case .notAvailable: Localizations.passkeyRegistrationRequiresIOS17OrLater
        case .unexpectedCredentialType: Localizations.unexpectedCredentialTypeReceived
        }
    }
}

// MARK: - PasskeyAssertionHandler

/// Bridges `ASAuthorizationControllerDelegate` callbacks for assertion to a Swift concurrency continuation.
///
@available(iOS 17, *)
private class PasskeyAssertionHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<Void, Error>
    private let window: ASPresentationAnchor

    init(continuation: CheckedContinuation<Void, Error>, window: ASPresentationAnchor) {
        self.continuation = continuation
        self.window = window
    }

    func authorizationController(
        controller _: ASAuthorizationController,
        didCompleteWithAuthorization _: ASAuthorization,
    ) {
        continuation.resume()
    }

    func authorizationController(controller _: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: error)
    }

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}

// MARK: - PasskeyRegistrationHandler

/// Bridges `ASAuthorizationControllerDelegate` callbacks for registration to a Swift concurrency continuation.
///
@available(iOS 17, *)
private class PasskeyRegistrationHandler: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding {
    private let continuation: CheckedContinuation<Void, Error>
    private let window: ASPresentationAnchor

    init(continuation: CheckedContinuation<Void, Error>, window: ASPresentationAnchor) {
        self.continuation = continuation
        self.window = window
    }

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

    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        window
    }
}

// MARK: - Private Globals

private var passkeyAssertionContinuationKey: UInt8 = 0
private var passkeyRegistrationContinuationKey: UInt8 = 0
