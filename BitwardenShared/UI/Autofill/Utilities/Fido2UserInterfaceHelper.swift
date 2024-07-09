import BitwardenSdk
import Combine

/// A helper to extend `Fido2UserInterface` protocol capabilities for Fido2 flows
/// depending on user interaction.
protocol Fido2UserInterfaceHelper: Fido2UserInterface {
    /// Sets the selected cipher as a result for credential for Fido2 creation.
    /// - Parameter result: The result of picking a cipher with the cipher or the error.
    func pickedCredentialForCreation(result: Result<CheckUserAndPickCredentialForCreationResult, Error>)

    /// Sets up the delegate to use on Fido2 user verification flows.
    /// - Parameter fido2UserVerificationMediatorDelegate: The delegate to use.
    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate)
}

/// Default implemenation of `Fido2UserInterfaceHelper`.
class DefaultFido2UserInterfaceHelper: Fido2UserInterfaceHelper {
    /// Mediator which manages user verification on Fido2 flows.
    private var fido2UserVerificationMediator: Fido2UserVerificationMediator

    /// Continuation when picking a credential for creation.
    var credentialForCreationContinuation: CheckedContinuation<CheckUserAndPickCredentialForCreationResult, Error>?

    /// Initializes a `DefaultFido2UserInterfaceHelper`.
    /// - Parameter fido2UserVerificationMediator: Mediator which manages user verification on Fido2 flows
    init(fido2UserVerificationMediator: Fido2UserVerificationMediator) {
        self.fido2UserVerificationMediator = fido2UserVerificationMediator
    }

    func checkUser(
        options: BitwardenSdk.CheckUserOptions,
        hint: BitwardenSdk.UiHint
    ) async throws -> BitwardenSdk.CheckUserResult {
        BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    }

    func pickCredentialForAuthentication(
        availableCredentials: [BitwardenSdk.CipherView]
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        // TODO: PM-8829 implement pick credential for auth
        CipherViewWrapper(cipher: .fixture())
    }

    func checkUserAndPickCredentialForCreation(
        options: BitwardenSdk.CheckUserOptions,
        newCredential: BitwardenSdk.Fido2CredentialNewView
    ) async throws -> BitwardenSdk.CheckUserAndPickCredentialForCreationResult {
        try await withCheckedThrowingContinuation { continuation in
            self.credentialForCreationContinuation = continuation
        }
    }

    func isVerificationEnabled() async -> Bool {
        fido2UserVerificationMediator.isPreferredVerificationEnabled()
    }

    func pickedCredentialForCreation(result: Result<CheckUserAndPickCredentialForCreationResult, Error>) {
        credentialForCreationContinuation?.resume(with: result)
    }

    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate) {
        fido2UserVerificationMediator.setupDelegate(
            fido2UserVerificationMediatorDelegate: fido2UserVerificationMediatorDelegate
        )
    }
}
