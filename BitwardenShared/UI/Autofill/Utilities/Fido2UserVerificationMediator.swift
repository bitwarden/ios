import BitwardenSdk

// MARK: - Fido2UserVerificationMediatorDelegate

/// A protocol for an `Fido2UserVerificationMediatorDelegate` which manages interaction
/// with the user from the user verification flows
///
@MainActor
protocol Fido2UserVerificationMediatorDelegate: UserVerificationDelegate {
    /// Set up the Bitwarden Pin for the current account
    ///
    func setupPin() async throws
}

// MARK: - Fido2UserVerificationMediator

/// A protocol for an `Fido2UserVerificationMediator` which manages user verification on Fido2 flows.
///
protocol Fido2UserVerificationMediator: AnyObject {
    /// Verifies the user depending on the `userVerificationPreference` and `credential`.
    /// - Parameters:
    ///   - userVerificationPreference: The Fido2 `BitwardenSdk.Verification` from the RP.
    ///   - credential: The selected cipher from which user needs to be verified.
    /// - Returns: The result of the verification and whether the user is present, in this case it's always present.
    func checkUser(
        userVerificationPreference: BitwardenSdk.Verification,
        credential: BitwardenSdk.CipherView
    ) async throws -> CheckUserResult

    /// Whether any verification method is enabled.
    /// - Returns: `true` if enabled, `false` otherwise.
    func isPreferredVerificationEnabled() -> Bool

    /// Sets up the delegate to use on Fido2 user verification flows.
    /// - Parameter fido2UserVerificationMediatorDelegate: The delegate to use.
    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate)
}

// MARK: - DefaultFido2UserVerificationMediator

/// A default implementation of an `Fido2UserVerificationMediator`.
///
class DefaultFido2UserVerificationMediator {
    // MARK: Types

    typealias UserVerificationContinuation = CheckedContinuation<UserVerificationResult, Error>

    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository

    /// The delegate used to manage user interaction from the user verification flow.
    private weak var fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate?

    /// The helper to execute user verification flows.
    private var userVerificationHelper: UserVerificationHelper

    /// The execution runner helper for user verification
    private let userVerificationRunner: UserVerificationRunner

    // MARK: Initialization

    /// Initialize a `DefaultFido2UserVerificationMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - userVerificationHelper: Helper to execute user verifications.
    ///   - userVerificationRunner: The execution runner helper for user verification.
    init(
        authRepository: AuthRepository,
        userVerificationHelper: UserVerificationHelper,
        userVerificationRunner: UserVerificationRunner
    ) {
        self.authRepository = authRepository
        self.userVerificationHelper = userVerificationHelper
        self.userVerificationRunner = userVerificationRunner
    }

    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate) {
        self.fido2UserVerificationMediatorDelegate = fido2UserVerificationMediatorDelegate
        userVerificationHelper.userVerificationDelegate = fido2UserVerificationMediatorDelegate
    }
}

// MARK: - Fido2UserVerificationMediator

extension DefaultFido2UserVerificationMediator: Fido2UserVerificationMediator {
    func checkUser(userVerificationPreference: BitwardenSdk.Verification,
                   credential: BitwardenSdk.CipherView) async throws -> CheckUserResult {
        if try await authRepository.shouldPerformMasterPasswordReprompt(reprompt: credential.reprompt) {
            // TODO: PM-8360 check if user interaction is needed to restart autofill action.

            let mpVerificationResult = try await userVerificationRunner.verifyWithAttempts(
                verifyFunction: userVerificationHelper.verifyMasterPassword
            )
            guard mpVerificationResult == .verified else {
                return CheckUserResult(userPresent: true, userVerified: false)
            }
            return CheckUserResult(userPresent: true, userVerified: true)
        }

        // TODO: PM-8361 verify if account has been unlocked in current transaction

        // TODO: PM-8360 check if user interaction is needed to restart autofill action.

        switch userVerificationPreference {
        case .discouraged:
            return CheckUserResult(userPresent: true, userVerified: false)
        case .preferred:
            let result = try await userVerificationHelper.verifyDeviceLocalAuth(
                reason: Localizations.userVerificationForPasskey
            )
            return CheckUserResult(userPresent: true, userVerified: result == .verified)
        case .required:
            let verifyDeviceLocalAuth = {
                try await self.userVerificationHelper.verifyDeviceLocalAuth(
                    reason: Localizations.userVerificationForPasskey
                )
            }
            let verifyPin = { try await self.userVerificationRunner.verifyWithAttempts(
                verifyFunction: self.userVerificationHelper.verifyPin)
            }
            let verifyMasterPassword = { try await self.userVerificationRunner.verifyWithAttempts(
                verifyFunction: self.userVerificationHelper.verifyMasterPassword)
            }
            let result = try await userVerificationRunner.verifyInQueue(verifyFunctions: [
                verifyDeviceLocalAuth,
                verifyPin,
                verifyMasterPassword,
            ])

            if result != .unableToPerform {
                return CheckUserResult(userPresent: true, userVerified: result == .verified)
            }

            guard let fido2UserVerificationMediatorDelegate else {
                return CheckUserResult(userPresent: true, userVerified: false)
            }

            try await fido2UserVerificationMediatorDelegate.setupPin()

            return CheckUserResult(userPresent: true, userVerified: true)
        }
    }

    func isPreferredVerificationEnabled() -> Bool {
        userVerificationHelper.canVerifyDeviceLocalAuth()
    }
}
