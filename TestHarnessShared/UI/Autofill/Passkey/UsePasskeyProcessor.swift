import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - UsePasskeyProcessor

/// The processor for the use passkey test screen.
///
final class UsePasskeyProcessor: StateProcessor<
    UsePasskeyState,
    UsePasskeyAction,
    UsePasskeyEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to perform passkey assertion through the Bitwarden SDK.
    private let passkeyService: PasskeyService

    // MARK: Initialization

    /// Initializes a `UsePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - passkeyService: The service used to perform passkey assertion through the
    ///     Bitwarden SDK.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        passkeyService: PasskeyService,
    ) {
        self.coordinator = coordinator
        self.passkeyService = passkeyService
        super.init(state: UsePasskeyState())
    }

    // MARK: Methods

    override func perform(_ effect: UsePasskeyEffect) async {
        switch effect {
        case let .deleteCredential(credential):
            await deleteCredential(credential)
        case .loadRegisteredCredentials:
            await loadRegisteredCredentials()
        case let .selectCredential(credential):
            await assertPasskey(credentialId: credential.credentialId, rpId: credential.rpId)
        }
    }

    // MARK: Private

    /// Orchestrates state transitions and calls `passkeyService.assertPasskey`.
    private func assertPasskey(credentialId: Data?, rpId: String) async {
        state.status = .inProgress
        do {
            let result = try await passkeyService.assertPasskey(credentialId: credentialId, rpId: rpId)
            state.status = .success(
                credentialId: result.credentialId.base64EncodedString(),
                rpId: rpId,
                userName: result.selectedCredential.credential.userName,
            )
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }

    /// Deletes the given credential, then reloads the registered credentials list.
    private func deleteCredential(_ credential: Fido2CredentialAutofillView) async {
        do {
            try await passkeyService.deleteCredential(cipherId: credential.cipherId)
            await loadRegisteredCredentials()
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }

    /// Loads the list of credentials registered so far, across app launches.
    private func loadRegisteredCredentials() async {
        defer { state.isLoadingCredentials = false }
        do {
            state.registeredCredentials = try await passkeyService.registeredCredentials()
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}
