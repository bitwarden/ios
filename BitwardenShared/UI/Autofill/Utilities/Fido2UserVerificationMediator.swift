import BitwardenSdk

// MARK: Fido2UserVerificationMediatorDelegate

/// A protocol for an `Fido2UserVerificationMediatorDelegate` which manages interaction
/// with the user from the user verification flows
///
@MainActor
protocol Fido2UserVerificationMediatorDelegate: UserVerificationDelegate {
    /// Set up the Bitwarden Pin for the current account
    ///
    func setupPin() async throws
}

// MARK: Fido2UserVerificationMediator

/// A protocol for an `Fido2UserVerificationMediator` which manages user verification on Fido2 flows.
///
protocol Fido2UserVerificationMediator: AnyObject {
    func checkUser(
        userVerificationPreference: Verification,
        credential: BitwardenSdk.CipherView
    ) async throws -> CheckUserResult
}

// MARK: - DefaultFido2UserVerificationMediator

/// A default implementation of an `Fido2UserVerificationMediator`.
///
class DefaultFido2UserVerificationMediator {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasLocalAuthService
        & HasStateService

    typealias UserVerificationContinuation = CheckedContinuation<UserVerificationResult, Error>

    // MARK: Properties

    /// The delegate used to manage user interaction from the user verification flow..
    private weak var fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate?

    /// The helper to execute user verification flows.
    private let userVerificationHelper: UserVerificationHelper

    /// The execution runner helper for user verification
    private let userVerificationRunner: UserVerificationRunner

    /// The services used by this mediator.
    private let services: Services

    // MARK: Initialization

    /// Initialize a `DefaultFido2UserVerificationMediator`.
    ///
    /// - Parameters:
    ///   - fido2UserVerificationMediatorDelegate: The service used by the application to manage account state.
    ///   - services: The services used by this mediator.
    ///   - userVerificationHelper: Helper to execute user verifications.
    ///   - userVerificationRunner: The execution runner helper for user verification.
    ///
    init(
        fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate?,
        services: Services,
        userVerificationHelper: UserVerificationHelper,
        userVerificationRunner: UserVerificationRunner
    ) {
        self.fido2UserVerificationMediatorDelegate = fido2UserVerificationMediatorDelegate
        self.services = services
        self.userVerificationHelper = userVerificationHelper
        self.userVerificationRunner = userVerificationRunner
    }

    /// Initialize a `DefaultFido2UserVerificationMediator`
    /// - Parameters:
    ///   - fido2UserVerificationMediatorDelegate: The service used by the application to manage account state
    ///   - services: The services used by this mediator
    ///   - userVerificationRunner: The execution runner helper for user verification
    convenience init(
        fido2UserVerificationMediatorDelegate: Fido2UserVerificationMediatorDelegate?,
        services: Services,
        userVerificationRunner: UserVerificationRunner
    ) {
        self.init(
            fido2UserVerificationMediatorDelegate: fido2UserVerificationMediatorDelegate,
            services: services,
            userVerificationHelper: DefaultUserVerificationHelper(
                userVerificationDelegate: fido2UserVerificationMediatorDelegate,
                services: services
            ),
            userVerificationRunner: userVerificationRunner
        )
    }
}

// MARK: - Fido2UserVerificationMediator

extension DefaultFido2UserVerificationMediator: Fido2UserVerificationMediator {
    func checkUser(userVerificationPreference: Verification,
                   credential: BitwardenSdk.CipherView) async throws -> CheckUserResult {
        if try await services.authRepository.shouldPerformMasterPasswordReprompt(reprompt: credential.reprompt) {
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
                because: Localizations.userVerificationForPasskey
            )
            return CheckUserResult(userPresent: true, userVerified: result == .verified)
        case .required:
            let verifyDeviceLocalAuth = {
                try await self.userVerificationHelper.verifyDeviceLocalAuth(
                    because: Localizations.userVerificationForPasskey
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

            if result != .cantPerform {
                return CheckUserResult(userPresent: true, userVerified: result == .verified)
            }

            guard let fido2UserVerificationMediatorDelegate else {
                return CheckUserResult(userPresent: true, userVerified: false)
            }

            try await fido2UserVerificationMediatorDelegate.setupPin()

            return CheckUserResult(userPresent: true, userVerified: true)
        }
    }
}

// MARK: Temporary until SDK update

// TODO: PM-8385 Replace for BitwardenSDK.Verification when sdk reference gets updated
enum Verification {
    case discouraged
    case preferred
    case required
}

// TODO: PM-8385 Replace for BitwardenSDK.Verification when sdk reference gets updated
struct CheckUserResult: Equatable {
    let userPresent: Bool
    let userVerified: Bool
}
