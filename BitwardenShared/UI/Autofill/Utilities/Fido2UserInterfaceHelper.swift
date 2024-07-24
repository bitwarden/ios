import BitwardenSdk
import Combine

// MARK: - Fido2UserInterfaceHelperDelegate

/// A protocol for an `Fido2UserInterfaceHelperDelegate` which manages interaction
/// with the user from the user verification flows and also some information
/// needed for the Fido2 flows.
///
@MainActor
protocol Fido2UserInterfaceHelperDelegate: Fido2UserVerificationMediatorDelegate {
    /// Whether the Fido2 flow for autofill is from credential list or not.
    var isAutofillingFromList: Bool { get }
}

/// A helper to extend `Fido2UserInterface` protocol capabilities for Fido2 flows
/// depending on user interaction.
protocol Fido2UserInterfaceHelper: Fido2UserInterface {
    /// The available credentials that can be used for authentication.
    var availableCredentialsForAuthentication: [BitwardenSdk.CipherView]? { get }
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

    /// Sets the selected cipher as a result for credential for Fido2 authentication.
    /// - Parameter result: The result of picking a cipher with the cipher or the error.
    func pickedCredentialForAuthentication(result: Result<CipherView, Error>)

    /// Sets the selected cipher as a result for credential for Fido2 creation.
    /// - Parameter result: The result of picking a cipher with the cipher or the error.
    func pickedCredentialForCreation(result: Result<CheckUserAndPickCredentialForCreationResult, Error>)

    /// Sets up the delegate to use on Fido2 user verification flows and to get information of the FIdo2 flow.
    /// - Parameter fido2UserInterfaceHelperDelegate: The delegate to use
    func setupDelegate(fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate)
}

/// Default implemenation of `Fido2UserInterfaceHelper`.
class DefaultFido2UserInterfaceHelper: Fido2UserInterfaceHelper {
    /// Mediator which manages user verification on Fido2 flows.
    private var fido2UserVerificationMediator: Fido2UserVerificationMediator

    /// The delegate for the FIdo2 flows information and user verification checks.
    private weak var fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate?

    /// Continuation when picking a credential for authentication.
    var credentialForAuthenticationContinuation: CheckedContinuation<CipherView, Error>?
    /// Continuation when picking a credential for creation.
    var credentialForCreationContinuation: CheckedContinuation<CheckUserAndPickCredentialForCreationResult, Error>?

    private(set) var availableCredentialsForAuthentication: [BitwardenSdk.CipherView]?
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
        guard let fido2UserInterfaceHelperDelegate else {
            throw Fido2Error.noDelegateSetup
        }

        guard await fido2UserInterfaceHelperDelegate.isAutofillingFromList else {
            guard availableCredentials.count == 1 else {
                throw Fido2Error.invalidOperationError
            }
            return CipherViewWrapper(cipher: availableCredentials[0])
        }

        defer {
            availableCredentialsForAuthentication = nil
        }

        availableCredentialsForAuthentication = availableCredentials
        let pickedCredential = try await withCheckedThrowingContinuation { continuation in
            self.credentialForAuthenticationContinuation = continuation
        }
        return CipherViewWrapper(cipher: pickedCredential)
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
        await fido2UserVerificationMediator.isPreferredVerificationEnabled()
    }

    func pickedCredentialForAuthentication(result: Result<CipherView, Error>) {
        credentialForAuthenticationContinuation?.resume(with: result)
    }

    func pickedCredentialForCreation(result: Result<CheckUserAndPickCredentialForCreationResult, Error>) {
        credentialForCreationContinuation?.resume(with: result)
    }

    func setupDelegate(fido2UserInterfaceHelperDelegate: Fido2UserInterfaceHelperDelegate) {
        self.fido2UserInterfaceHelperDelegate = fido2UserInterfaceHelperDelegate
        fido2UserVerificationMediator.setupDelegate(
            fido2UserVerificationMediatorDelegate: fido2UserInterfaceHelperDelegate
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
