import AuthenticationServices
import BitwardenKit
import Combine
import CryptoKit
import UIKit

// MARK: - UsePasskeyProcessor

/// The processor for the use passkey test screen.
///
@available(iOS 17, *)
class UsePasskeyProcessor: StateProcessor<
    UsePasskeyState,
    UsePasskeyAction,
    UsePasskeyEffect,
> {
    // MARK: Types

    typealias PerformAssertion = (
        _ rpId: String,
        _ allowedCredentials: [StoredPasskeyCredential],
        _ presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws -> StoredPasskeyCredential

    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// A delegate used to obtain a presentation anchor for the passkey sheet.
    private weak var delegate: UsePasskeyProcessorDelegate?

    // MARK: Internal for Testability

    /// Performs the passkey assertion flow. Injected for testability.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier.
    ///   - allowedCredentials: The previously stored credentials to scope the request to and
    ///     verify the resulting assertion against.
    ///   - presentationAnchor: Provides the window used to present the passkey sheet.
    let performAssertion: PerformAssertion

    /// Reads previously created passkey credentials to verify assertions against.
    let credentialStore: PasskeyCredentialStore

    // MARK: Initialization

    /// Initializes a `UsePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate used to obtain the presentation anchor.
    ///   - performAssertion: Performs the passkey assertion flow. Defaults to the real
    ///     `ASAuthorizationController`-based implementation; overridable in tests.
    ///   - credentialStore: Reads previously created passkey credentials. Defaults to a
    ///     `UserDefaults`-backed store; overridable in tests.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: UsePasskeyProcessorDelegate?,
        performAssertion: @escaping PerformAssertion = UsePasskeyProcessor.performPasskeyAssertion,
        credentialStore: PasskeyCredentialStore = DefaultPasskeyCredentialStore(),
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.performAssertion = performAssertion
        self.credentialStore = credentialStore
        super.init(state: UsePasskeyState())
    }

    // MARK: Static Methods

    /// The real passkey assertion implementation using `ASAuthorizationController`.
    ///
    /// - Parameters:
    ///   - rpId: The relying party identifier.
    ///   - allowedCredentials: The previously stored credentials to scope the request to and
    ///     verify the resulting assertion against.
    ///   - presentationAnchor: Provides the window used to present the passkey sheet.
    /// - Returns: The stored credential the assertion was verified against.
    ///
    private static func performPasskeyAssertion(
        rpId: String,
        allowedCredentials: [StoredPasskeyCredential],
        presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws -> StoredPasskeyCredential {
        let window = await presentationAnchor()

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let request = provider.createCredentialAssertionRequest(challenge: challenge)
        request.allowedCredentials = allowedCredentials.map { credential in
            ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: credential.credentialId)
        }

        let assertion = try await PasskeyAuthorizationBridge<ASAuthorizationPlatformPublicKeyCredentialAssertion>(
            window: window,
        ).perform(request: request)

        return try PasskeyAssertionVerifier.verify(
            rpId: rpId,
            assertion: PasskeyAssertionVerifier.RawAssertion(
                credentialId: assertion.credentialID,
                rawAuthenticatorData: assertion.rawAuthenticatorData,
                signature: assertion.signature,
                rawClientDataJSON: assertion.rawClientDataJSON,
            ),
            expectedChallenge: challenge,
            candidates: allowedCredentials,
        )
    }

    // MARK: Methods

    override func receive(_ action: UsePasskeyAction) {
        switch action {
        case let .rpIdChanged(newValue): state.rpId = newValue
        }
    }

    override func perform(_ effect: UsePasskeyEffect) async {
        switch effect {
        case .assertPasskey: await assertPasskey()
        }
    }

    // MARK: Private

    /// Orchestrates state transitions and calls `performAssertion`.
    private func assertPasskey() async {
        state.status = .inProgress
        do {
            let storedCredentials = try credentialStore.fetchAll().filter { $0.rpId == state.rpId }
            let credential = try await performAssertion(state.rpId, storedCredentials) { [weak self] in
                await self?.delegate?.presentationAnchorForPasskeyAssertion() ?? UIWindow()
            }
            state.status = .success(credential: credential)
        } catch let error as PasskeyAssertionVerifier.VerificationError {
            state.status = .verificationFailure(error.localizedDescription)
        } catch let error as ASAuthorizationError where error.code == .canceled {
            state.status = .idle
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}

// MARK: - UsePasskeyProcessorDelegate

/// A delegate that provides a presentation anchor for the passkey assertion sheet.
///
protocol UsePasskeyProcessorDelegate: AnyObject {
    /// Returns the window to use as the presentation anchor for the passkey assertion sheet.
    @MainActor
    func presentationAnchorForPasskeyAssertion() async -> ASPresentationAnchor
}
