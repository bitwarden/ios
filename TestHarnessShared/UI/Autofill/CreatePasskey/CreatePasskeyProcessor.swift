import AuthenticationServices
import BitwardenKit
import Combine
import CryptoKit
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
    ) async throws -> StoredPasskeyCredential

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

    /// Persists successfully created passkey credentials for later use in the verify flow.
    let credentialStore: PasskeyCredentialStore

    // MARK: Initialization

    /// Initializes a `CreatePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - delegate: The delegate used to obtain the presentation anchor.
    ///   - performRegistration: Performs the passkey registration flow. Defaults to the real
    ///     `ASAuthorizationController`-based implementation; overridable in tests.
    ///   - credentialStore: Persists successfully created passkey credentials. Defaults to a
    ///     `UserDefaults`-backed store; overridable in tests.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        delegate: CreatePasskeyProcessorDelegate?,
        performRegistration: @escaping PerformRegistration = CreatePasskeyProcessor.performPasskeyRegistration,
        credentialStore: PasskeyCredentialStore = DefaultPasskeyCredentialStore(),
    ) {
        self.coordinator = coordinator
        self.delegate = delegate
        self.performRegistration = performRegistration
        self.credentialStore = credentialStore
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
    /// - Returns: The credential data to persist for later use in the verify flow.
    ///
    private static func performPasskeyRegistration(
        rpId: String,
        userName: String,
        displayName: String,
        presentationAnchor: () async -> ASPresentationAnchor,
    ) async throws -> StoredPasskeyCredential {
        let window = await presentationAnchor()

        let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
        let challenge = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        let userId = Data(UUID().uuidString.utf8)
        let request = provider.createCredentialRegistrationRequest(
            challenge: challenge,
            name: userName,
            userID: userId,
        )
        let resolvedDisplayName = displayName.isEmpty ? userName : displayName
        request.displayName = resolvedDisplayName

        let registration = try await PasskeyAuthorizationBridge<ASAuthorizationPlatformPublicKeyCredentialRegistration>(
            window: window,
        ).perform(request: request)

        guard let attestationObject = registration.rawAttestationObject else {
            throw PasskeyRegistrationError.missingAttestationObject
        }
        let parsed = try COSEKeyParser.parseCredential(fromAttestationObject: attestationObject)

        // Uses the parser's own extracted credential ID (rather than `registration.credentialID`)
        // so this path continuously exercises the same CBOR parsing the future verify flow will
        // depend on.
        return StoredPasskeyCredential(
            createdAt: Date(),
            credentialId: parsed.credentialId,
            displayName: resolvedDisplayName,
            publicKeyX963: parsed.publicKeyX963,
            rpId: rpId,
            userName: userName,
        )
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
            let credential = try await performRegistration(
                state.rpId,
                state.userName,
                state.displayName,
            ) { [weak self] in
                await self?.delegate?.presentationAnchorForPasskeyRegistration() ?? UIWindow()
            }
            do {
                try credentialStore.save(credential)
                state.status = .success
            } catch {
                state.status = .persistenceFailure(credential: credential, message: error.localizedDescription)
            }
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
    /// The authorization response did not include an attestation object.
    case missingAttestationObject

    var errorDescription: String? {
        switch self {
        case .missingAttestationObject:
            Localizations.missingAttestationObjectReceived
        }
    }
}
