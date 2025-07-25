import BitwardenResources
import BitwardenSdk

// MARK: - Fido2UserVerificationMediatorDelegate

/// A protocol for an `Fido2UserVerificationMediatorDelegate` which manages interaction
/// with the user from the user verification flows
///
@MainActor
protocol Fido2UserVerificationMediatorDelegate: UserVerificationDelegate {
    /// Performs additional logic when user interaction is needed and throws if needed.
    func onNeedsUserInteraction() async throws
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
    /// - Throws: Particularly `Fido2UserVerificationError.masterPasswordRepromptFailed` when
    /// master password reprompt was performed and failed.
    func checkUser(
        userVerificationPreference: BitwardenSdk.Verification,
        credential: Fido2UserVerifiableCipherView
    ) async throws -> CheckUserResult

    /// Whether any verification method is enabled.
    /// - Returns: `true` if enabled, `false` otherwise.
    func isPreferredVerificationEnabled() async -> Bool

    /// Sets up the delegate to use on Fido2 user verification flows.
    /// - Parameter fido2UserVerificationMediatorDelegate: The delegate to use.
    func setupDelegate(fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate)
}

// MARK: - Fido2UserVerifiableCipherView

/// A protocol to be used by `Fido2UserVerificationMediator` when checking user on FIdo2 flows allowing to access
/// some cipher data.
protocol Fido2UserVerifiableCipherView {
    var reprompt: BitwardenSdk.CipherRepromptType { get }
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

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The helper to execute user verification flows.
    private var userVerificationHelper: UserVerificationHelper

    /// The execution runner helper for user verification
    private let userVerificationRunner: UserVerificationRunner

    // MARK: Initialization

    /// Initialize a `DefaultFido2UserVerificationMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - stateService: The service used by the application to manage account state.
    ///   - userVerificationHelper: Helper to execute user verifications.
    ///   - userVerificationRunner: The execution runner helper for user verification.
    init(
        authRepository: AuthRepository,
        stateService: StateService,
        userVerificationHelper: UserVerificationHelper,
        userVerificationRunner: UserVerificationRunner
    ) {
        self.authRepository = authRepository
        self.stateService = stateService
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
                   credential: Fido2UserVerifiableCipherView) async throws -> CheckUserResult {
        if try await authRepository.shouldPerformMasterPasswordReprompt(reprompt: credential.reprompt) {
            try await fido2UserVerificationMediatorDelegate?.onNeedsUserInteraction()

            let mpVerificationResult = try await userVerificationRunner.verifyWithAttempts(
                verifyFunction: userVerificationHelper.verifyMasterPassword
            )
            guard mpVerificationResult == .verified else {
                throw Fido2UserVerificationError.masterPasswordRepromptFailed
            }
            return CheckUserResult(userPresent: true, userVerified: true)
        }

        if let hasBeenUnlocked = try? await stateService.getAccountHasBeenUnlockedInteractively(),
           hasBeenUnlocked {
            return CheckUserResult(userPresent: true, userVerified: true)
        }

        try await fido2UserVerificationMediatorDelegate?.onNeedsUserInteraction()

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

            try await userVerificationHelper.setupPin()

            return CheckUserResult(userPresent: true, userVerified: true)
        }
    }

    func isPreferredVerificationEnabled() async -> Bool {
        if let hasBeenUnlocked = try? await stateService.getAccountHasBeenUnlockedInteractively(),
           hasBeenUnlocked {
            return true
        }

        return userVerificationHelper.canVerifyDeviceLocalAuth()
    }
}
