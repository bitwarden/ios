import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - SDKUsePasskeyProcessor

/// The processor for the SDK-backed use passkey test screen.
///
final class SDKUsePasskeyProcessor: StateProcessor<
    SDKUsePasskeyState,
    SDKUsePasskeyAction,
    SDKUsePasskeyEffect,
> {
    // MARK: Private Properties

    /// The coordinator that handles navigation.
    private let coordinator: AnyCoordinator<RootRoute, Void>

    /// The service used to perform passkey assertion through the Bitwarden SDK.
    private let sdkPasskeyService: SDKPasskeyService

    // MARK: Initialization

    /// Initializes an `SDKUsePasskeyProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - sdkPasskeyService: The service used to perform passkey assertion through the
    ///     Bitwarden SDK.
    ///
    init(
        coordinator: AnyCoordinator<RootRoute, Void>,
        sdkPasskeyService: SDKPasskeyService,
    ) {
        self.coordinator = coordinator
        self.sdkPasskeyService = sdkPasskeyService
        super.init(state: SDKUsePasskeyState())
    }

    // MARK: Methods

    override func perform(_ effect: SDKUsePasskeyEffect) async {
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

    /// Orchestrates state transitions and calls `sdkPasskeyService.assertPasskey`.
    private func assertPasskey(credentialId: Data?, rpId: String) async {
        state.status = .inProgress
        do {
            let result = try await sdkPasskeyService.assertPasskey(credentialId: credentialId, rpId: rpId)
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
            try await sdkPasskeyService.deleteCredential(cipherId: credential.cipherId)
            await loadRegisteredCredentials()
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }

    /// Loads the list of credentials registered so far, across app launches.
    private func loadRegisteredCredentials() async {
        do {
            state.registeredCredentials = try await sdkPasskeyService.registeredCredentials()
        } catch {
            state.status = .failure(error.localizedDescription)
        }
    }
}
