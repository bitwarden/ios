import BitwardenKit
import BitwardenResources

/// Helper for user verification flows.
///
protocol UserVerificationHelper {
    var userVerificationDelegate: UserVerificationDelegate? { get set }

    /// Whether device local auth is authorized thus can be verified.
    /// - Returns: `true` if authorized, `false` otherwise.
    func canVerifyDeviceLocalAuth() -> Bool

    /// Set up the Bitwarden Pin for the current account
    func setupPin() async throws

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
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The service used by the application to evaluate local auth policies.
    let localAuthService: LocalAuthService

    /// The delegate used to manage user interaction from the user verification flow.
    weak var userVerificationDelegate: UserVerificationDelegate?

    // MARK: Initialization

    /// Initialize a `DefaultUserVerificationHelper`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - localAuthService:  The service used by the application to evaluate local auth policies.
    init(
        authRepository: AuthRepository,
        errorReporter: ErrorReporter,
        localAuthService: LocalAuthService
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.localAuthService = localAuthService
    }
}

// MARK: - UserVerificationHelper

extension DefaultUserVerificationHelper: UserVerificationHelper {
    typealias UserVerificationContinuation = CheckedContinuation<UserVerificationResult, Error>

    func canVerifyDeviceLocalAuth() -> Bool {
        localAuthService.getDeviceAuthStatus() == .authorized
    }

    @MainActor
    func setupPin() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            guard let userVerificationDelegate else {
                continuation.resume(throwing: Fido2Error.failedToSetupPin)
                return
            }

            userVerificationDelegate.showAlert(.enterPINCode(
                onCancelled: { () in
                    continuation.resume(throwing: UserVerificationError.cancelled)
                },
                settingUp: true,
                completion: { pin in
                    do {
                        guard !pin.isEmpty else {
                            throw Fido2Error.failedToSetupPin
                        }

                        try await self.authRepository.setPins(pin, requirePasswordAfterRestart: false)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            ))
        }
    }

    func verifyDeviceLocalAuth(reason: String) async throws -> UserVerificationResult {
        let localAuthPermission = localAuthService.getDeviceAuthStatus()
        guard localAuthPermission == .authorized else {
            return .unableToPerform
        }

        do {
            let isValid = try await localAuthService.evaluateDeviceOwnerPolicy(
                reason: reason
            )
            return isValid ? .verified : .notVerified
        } catch LocalAuthError.cancelled {
            throw UserVerificationError.cancelled
        }
    }

    func verifyMasterPassword() async throws -> UserVerificationResult {
        guard try await authRepository.canVerifyMasterPassword() else {
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
                        let isValid = try await authRepository.validatePassword(password)
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
                        errorReporter.log(error: error)
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
        guard try await authRepository.isPinUnlockAvailable() else {
            return .unableToPerform
        }

        return try await withCheckedThrowingContinuation { (continuation: UserVerificationContinuation) in
            let alert = Alert.enterPINCode(
                onCancelled: { () in
                    continuation.resume(throwing: UserVerificationError.cancelled)
                },
                settingUp: false,
                completion: { [weak self] pin in
                    guard let self else { return }

                    do {
                        guard try await authRepository.validatePin(pin: pin) else {
                            userVerificationDelegate?.showAlert(
                                .defaultAlert(title: Localizations.invalidPIN),
                                onDismissed: {
                                    continuation.resume(returning: .notVerified)
                                }
                            )
                            return
                        }

                        continuation.resume(returning: .verified)
                    } catch {
                        errorReporter.log(error: error)
                        continuation.resume(returning: .unableToPerform)
                    }
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
