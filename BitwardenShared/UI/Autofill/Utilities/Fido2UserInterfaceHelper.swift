import BitwardenSdk
import Combine

/// A helper to extend `Fido2UserInterface` protocol capabilities for Fido2 flows
/// depending on user interaction.
protocol Fido2UserInterfaceHelper: Fido2UserInterface {
    /// The `BitwardenSdk.CheckUserOptions` the SDK provides while in Fido2 creation flow.
    var fido2CreationOptions: BitwardenSdk.CheckUserOptions? { get }
    /// The `BitwardenSdk.Fido2CredentialNewView` the SDK provides while in FIdo2 creation flow.
    var fido2CredentialNewView: BitwardenSdk.Fido2CredentialNewView? { get }

    /// Verifies the user depending on the `userVerificationPreference` and `credential`.
    ///
    /// This is added here so we don't use `Fido2UserVerificationMediator` elsewhere and avoid
    /// having to deal with trouble with the delegates.
    /// Moreover, we can use this helper for utilities on user interactionfor Fido2 flows.
    ///
    /// - Parameters:
    ///   - userVerificationPreference: The Fido2 `BitwardenSdk.Verification` from the RP.
    ///   - credential: The selected cipher from which user needs to be verified.
    ///   - shouldThrowEnforcingRequiredVerification: Whether this should throw an error when enforcing
    ///   required user verfiication and it fails to comply it.
    /// - Returns: The result of the verification and whether the user is present, in this case it's always present.
    /// - Throws:
    ///   - `Fido2UserVerificationError.masterPasswordRepromptFailed` when failed entering master password reprompt.
    ///   - `Fido2UserVerificationError.requiredEnforcementFailed` when enforcing required
    /// verification fails.
    func checkUser(
        userVerificationPreference: BitwardenSdk.Verification,
        credential: BitwardenSdk.CipherView,
        shouldThrowEnforcingRequiredVerification: Bool
    ) async throws -> CheckUserResult

    /// Sets the selected cipher as a result for credential for Fido2 creation.
    /// - Parameter result: The result of picking a cipher with the cipher or the error.
    func pickedCredentialForCreation(result: Result<CheckUserAndPickCredentialForCreationResult, Error>)

    /// Sets up the delegate to use on Fido2 user verification flows.
    /// - Parameter fido2UserVerificationMediatorDelegate: The delegate to use
    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate)
}

/// Default implemenation of `Fido2UserInterfaceHelper`.
class DefaultFido2UserInterfaceHelper: Fido2UserInterfaceHelper {
    /// Mediator which manages user verification on Fido2 flows.
    private var fido2UserVerificationMediator: Fido2UserVerificationMediator

    /// Continuation when picking a credential for creation.
    var credentialForCreationContinuation: CheckedContinuation<CheckUserAndPickCredentialForCreationResult, Error>?

    private(set) var fido2CreationOptions: BitwardenSdk.CheckUserOptions?
    private(set) var fido2CredentialNewView: BitwardenSdk.Fido2CredentialNewView?

    /// Initializes a `DefaultFido2UserInterfaceHelper`.
    /// - Parameter fido2UserVerificationMediator: Mediator which manages user verification on Fido2 flows
    init(fido2UserVerificationMediator: Fido2UserVerificationMediator) {
        self.fido2UserVerificationMediator = fido2UserVerificationMediator
    }

    func checkUser(
        options: BitwardenSdk.CheckUserOptions,
        hint: BitwardenSdk.UiHint
    ) async throws -> BitwardenSdk.CheckUserResult {
        if case let .requestExistingCredential(cipherView) = hint {
            return try await checkUser(
                userVerificationPreference: options.requireVerification,
                credential: cipherView,
                shouldThrowEnforcingRequiredVerification: false
            )
        }

        return BitwardenSdk.CheckUserResult(userPresent: true, userVerified: true)
    }

    func checkUser(
        userVerificationPreference: BitwardenSdk.Verification,
        credential: BitwardenSdk.CipherView,
        shouldThrowEnforcingRequiredVerification: Bool
    ) async throws -> CheckUserResult {
        let result = try await fido2UserVerificationMediator.checkUser(
            userVerificationPreference: userVerificationPreference,
            credential: credential
        )

        if !result.userVerified, shouldThrowEnforcingRequiredVerification {
            if await checkEnforceRequiredVerification(userVerificationPreference: userVerificationPreference) {
                throw Fido2UserVerificationError.requiredEnforcementFailed
            }
        }

        return result
    }

    func pickCredentialForAuthentication(
        availableCredentials: [BitwardenSdk.CipherView]
    ) async throws -> BitwardenSdk.CipherViewWrapper {
        // TODO: PM-8829 implement pick credential for auth
        throw Fido2Error.invalidOperationError
    }

    func checkUserAndPickCredentialForCreation(
        options: BitwardenSdk.CheckUserOptions,
        newCredential: BitwardenSdk.Fido2CredentialNewView
    ) async throws -> BitwardenSdk.CheckUserAndPickCredentialForCreationResult {
        defer {
            fido2CreationOptions = nil
            fido2CredentialNewView = nil
        }
        fido2CreationOptions = options
        fido2CredentialNewView = newCredential

        return try await withCheckedThrowingContinuation { continuation in
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

    // MARK: Private

    /// Checks if we should enforce `required` behavior on the passed `userVerificationPreference`
    /// - Parameters:
    ///   - userVerificationPreference: The preference to check.
    /// - Returns: `true` if should enforce `required` behavior, `false` otherwise.
    private func checkEnforceRequiredVerification(userVerificationPreference: BitwardenSdk.Verification) async -> Bool {
        switch userVerificationPreference {
        case .discouraged:
            return false
        case .preferred:
            return await isVerificationEnabled()
        case .required:
            return true
        }
    }
}
