import BitwardenResources

// MARK: - VaultUnlockSetupHelper

/// A protocol for a helper used to set up vault unlock methods.
///
protocol VaultUnlockSetupHelper: AnyObject {
    /// Enables or disables biometric vault unlock.
    ///
    /// - Parameters:
    ///   - enabled: Whether to enable biometric vault unlock.
    ///   - showAlert: A closure used to handle showing an alert if needed while toggling biometric
    ///     vault unlock.
    /// - Returns: The biometric unlock status after vault unlock has been updated.
    ///
    func setBiometricUnlock(
        enabled: Bool,
        showAlert: @escaping @MainActor (Alert) -> Void
    ) async -> BiometricsUnlockStatus?

    /// Enables or disables pin vault unlock.
    ///
    /// - Parameters:
    ///   - enabled: Whether to enable pin vault unlock.
    ///   - showAlert: A closure used to handle showing an alert if needed while toggling pin vault unlock.
    /// - Returns: Whether pin unlock is enabled after vault unlock has been updated.
    ///
    func setPinUnlock(
        enabled: Bool,
        showAlert: @escaping @MainActor (Alert) -> Void
    ) async -> Bool
}

// MARK: - VaultUnlockSetupHelperError

/// Errors thrown by a `VaultUnlockSetupHelper`.
///
enum VaultUnlockSetupHelperError: Error {
    /// The user cancelled setting up an unlock method.
    case userCancelled
}

// MARK: - DefaultVaultUnlockSetupHelper

/// A default implementation of `VaultUnlockSetupHelper` which is used to set up vault unlock methods.
///
@MainActor
class DefaultVaultUnlockSetupHelper {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBiometricsRepository
        & HasErrorReporter
        & HasStateService

    // MARK: Properties

    /// The services used by this helper.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `DefaultVaultUnlockSetupHelper`.
    ///
    /// - Parameters:
    ///   - services: The services used by this helper.
    ///
    init(services: Services) {
        self.services = services
    }

    // MARK: Private

    /// Shows an alert for the user to enter their pin for vault unlock.
    ///
    /// - Parameter showAlert: A closure used to handling showing the alert.
    /// - Returns: The pin that the user entered.
    ///
    private func showEnterPinAlert(showAlert: @escaping (Alert) -> Void) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            showAlert(.enterPINCode(
                onCancelled: {
                    continuation.resume(throwing: VaultUnlockSetupHelperError.userCancelled)
                },
                completion: { pin in
                    continuation.resume(returning: pin)
                }
            ))
        }
    }

    /// Shows an alert asking the user whether they want to require their master password to unlock
    /// the vault when the app restarts.
    ///
    /// - Parameters:
    ///   - biometricType: The biometric type the app supports.
    ///   - showAlert: A closure used to handle showing the alert.
    /// - Returns: Whether the user wants to require their master password on app restart.
    ///
    private func showUnlockWithPinAlert(
        biometricType: BiometricAuthenticationType?,
        showAlert: @escaping (Alert) -> Void
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            showAlert(.unlockWithPINCodeAlert(biometricType: biometricType) { requirePassword in
                continuation.resume(returning: requirePassword)
            })
        }
    }
}

// MARK: - DefaultVaultUnlockSetupHelper+VaultUnlockSetupHelper

extension DefaultVaultUnlockSetupHelper: VaultUnlockSetupHelper {
    func setBiometricUnlock(
        enabled: Bool,
        showAlert: @escaping @MainActor (Alert) -> Void
    ) async -> BiometricsUnlockStatus? {
        do {
            try await services.authRepository.allowBioMetricUnlock(enabled)
            return try await services.biometricsRepository.getBiometricUnlockStatus()
        } catch {
            services.errorReporter.log(error: error)
            showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))

            // In the case of an error, still attempt to return the unlock status. This status may
            // be used by the UI to determine whether biometrics are available on the device.
            return try? await services.biometricsRepository.getBiometricUnlockStatus()
        }
    }

    func setPinUnlock(
        enabled: Bool,
        showAlert: @escaping @MainActor (Alert) -> Void
    ) async -> Bool {
        do {
            guard enabled else {
                try await services.authRepository.clearPins()
                return false
            }

            let pin = try await showEnterPinAlert(showAlert: showAlert)
            guard !pin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

            let userHasMasterPassword = try await services.stateService.getUserHasMasterPassword()
            let biometricType = services.biometricsRepository.getBiometricAuthenticationType()
            let requirePasswordAfterRestart = if userHasMasterPassword {
                await showUnlockWithPinAlert(biometricType: biometricType, showAlert: showAlert)
            } else {
                false
            }

            try await services.authRepository.setPins(
                pin,
                requirePasswordAfterRestart: requirePasswordAfterRestart
            )

            return true
        } catch VaultUnlockSetupHelperError.userCancelled {
            return !enabled
        } catch {
            services.errorReporter.log(error: error)
            showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return false
        }
    }
}
