/// Helper for user verification flows.
///
protocol UserVerificationHelper {
    /// Performs OS local auth, e.g. biometrics or pin/pattern
    /// - Parameter reason: The reason to be displayed to the user when evaluating the policy if needed
    /// - Returns: An `UserVerificationResult` with the verification result
    /// - Throws: `UserVerificationError.cancelled` if the user cancels the auth.
    func verifyDeviceLocalAuth(reason: String) async throws -> UserVerificationResult

    /// Shows an alert to the user to enter their master password and verifies it.
    /// - Returns: An `UserVerificationResult` with the verification result.
    /// - Throws: `UserVerificationError.cancelled` if the user cancels the alert.
    func verifyMasterPassword() async throws -> UserVerificationResult

    /// Shows an alert to the user to enter their pin and verifies it.
    /// - Returns: An `UserVerificationResult` with the verification result.
    /// - Throws: `UserVerificationError.cancelled` if the user cancels the alert.
    func verifyPin() async throws -> UserVerificationResult
}

// MARK: - DefaultUserVerificationHelper

/// Default implementation of `UserVerificationHelper`
///
class DefaultUserVerificationHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasLocalAuthService

    // MARK: Properties

    /// The delegate used to manage user interaction from the user verification flow..
    private weak var userVerificationDelegate: UserVerificationDelegate?

    /// The services used by this mediator.
    private let services: Services

    // MARK: Initialization

    /// Initialize a `DefaultUserVerificationHelper`.
    ///
    /// - Parameters:
    ///   - userVerificationMediatorDelegate: The delegate to manage user interaction from the user verification flow.
    ///   - services: The services used by this mediator.
    ///
    init(
        userVerificationDelegate: UserVerificationDelegate?,
        services: Services
    ) {
        self.userVerificationDelegate = userVerificationDelegate
        self.services = services
    }
}

// MARK: - UserVerificationHelper

extension DefaultUserVerificationHelper: UserVerificationHelper {
    typealias UserVerificationContinuation = CheckedContinuation<UserVerificationResult, Error>

    func verifyDeviceLocalAuth(reason: String) async throws -> UserVerificationResult {
        let localAuthPermission = services.localAuthService.getDeviceAuthStatus()
        guard localAuthPermission == .authorized else {
            return .unableToPerform
        }

        do {
            let isValid = try await services.localAuthService.evaluateDeviceOwnerPolicy(
                reason: reason
            )
            return isValid ? .verified : .notVerified
        } catch LocalAuthError.cancelled {
            throw UserVerificationError.cancelled
        }
    }

    func verifyMasterPassword() async throws -> UserVerificationResult {
        guard try await services.authRepository.canVerifyMasterPassword() else {
            return .unableToPerform
        }

        return try await withCheckedThrowingContinuation { (continuation: UserVerificationContinuation) in
            let alert = Alert.masterPasswordPrompt(
                onCancelled: { () in
                    continuation.resume(throwing: UserVerificationError.cancelled)
                },
                completion: { [weak self] password in
                    guard let self else { return }

                    do {
                        let isValid = try await services.authRepository.validatePassword(password)
                        guard isValid else {
                            userVerificationDelegate?.showAlert(
                                .defaultAlert(title: Localizations.invalidMasterPassword),
                                onDismissed: {
                                    continuation.resume(returning: .notVerified)
                                }
                            )
                            return
                        }
                        continuation.resume(returning: .verified)
                    } catch {
                        services.errorReporter.log(error: error)
                        continuation.resume(returning: .unableToPerform)
                    }
                }
            )

            Task {
                await self.userVerificationDelegate?.showAlert(alert)
            }
        }
    }

    func verifyPin() async throws -> UserVerificationResult {
        guard try await services.authRepository.isPinUnlockAvailable() else {
            return .unableToPerform
        }

        return try await withCheckedThrowingContinuation { (continuation: UserVerificationContinuation) in
            let alert = Alert.enterPINCode(
                onCancelled: { () in
                    continuation.resume(throwing: UserVerificationError.cancelled)
                },
                settingUp: false,
                completion: { _ in
                    // TODO: PM-8388 Perform PIN verification when method available from SDK
                    continuation.resume(returning: .notVerified)
                }
            )

            Task {
                await self.userVerificationDelegate?.showAlert(alert)
            }
        }
    }
}

// MARK: - UserVerificationResult

/// An enum with the possible results when verifying a user
///
enum UserVerificationResult {
    case unableToPerform
    case verified
    case notVerified
}

// MARK: - UserVerificationError

/// Errors corresponding to user verification flows.
///
public enum UserVerificationError: Error {
    case cancelled
}

// MARK: - UserVerificationDelegate

/// A protocol for an `UserVerificationHelper` which manages interaction
/// with the user from the user verification flows
///
@MainActor
protocol UserVerificationDelegate: AnyObject {
    /// Shows the provided alert to the user.
    ///
    /// - Parameter alert: The alert to show.
    ///
    func showAlert(_ alert: Alert)

    /// Shows an alert to the user
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?)
}
