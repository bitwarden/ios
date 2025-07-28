import BitwardenResources
import LocalAuthentication
import OSLog

// MARK: - BiometricsService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsService: AnyObject {
    /// Evaluate's the users biometrics policy via `BiometricAuthorizationStatus`
    ///
    /// - Parameter biometricAuthStatus: The status to be checked.
    ///     If `true`, a system dialog may prompt the user for permissions.
    /// - Returns: A `Bool` indicating if the evaluation was successful.
    ///
    func evaluateBiometricPolicy(
        _ suppliedContext: LAContext?,
        for biometricAuthStatus: BiometricAuthorizationStatus
    ) async -> Bool

    /// Returns the status for device BiometricAuthenticationType.
    ///
    /// - Returns: The `BiometricAuthenticationType`.
    ///
    func getBiometricAuthenticationType(_ suppliedContext: LAContext?) -> BiometricAuthenticationType?

    /// Returns the status for user BiometricAuthentication.
    ///
    /// - Returns: The a `BiometricAuthorizationStatus`.
    ///
    func getBiometricAuthStatus() -> BiometricAuthorizationStatus

    /// Returns the `Data` for device evaluatedPolicyDomainState.
    ///
    /// - Returns: The `Data` for evaluatedPolicyDomainState.
    ///
    func getBiometricIntegrityState() -> Data?
}

extension BiometricsService {
    /// Evaluate's the users biometrics policy via `BiometricAuthorizationStatus`
    ///
    /// - Returns: An evaluated status for the user's biometric authorization.
    ///
    func evaluateBiometricPolicy() async throws -> Bool {
        let initialStatus = getBiometricAuthStatus()
        return await evaluateBiometricPolicy(nil, for: initialStatus)
    }
}

class DefaultBiometricsService: BiometricsService {
    func evaluateBiometricPolicy(
        _ suppliedContext: LAContext?,
        for biometricAuthStatus: BiometricAuthorizationStatus
    ) async -> Bool {
        // First check if the existing status can be evaluated.
        guard case .authorized = biometricAuthStatus else {
            // If not, return false
            return false
        }

        // Then, evaluate the policy, which prompts the user for FaceID
        //  or biometrics permissions.
        let authContext = suppliedContext ?? LAContext()
        do {
            let result = try await authContext.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: Localizations.useBiometricsToUnlock
            )
            return result
        } catch {
            Logger.processor.error("Error evaluating biometrics policy: \(error)")
            return false
        }
    }

    func getBiometricAuthenticationType(_ suppliedContext: LAContext?) -> BiometricAuthenticationType? {
        let authContext = suppliedContext ?? LAContext()
        var error: NSError?

        guard authContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            Logger.processor.error("Error checking biometrics type: \(error)")
            return nil
        }

        switch authContext.biometryType {
        case .none,
             .opticID:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }

    func getBiometricAuthStatus() -> BiometricAuthorizationStatus {
        let context = LAContext()
        var error: NSError?

        let biometricAuthType = getBiometricAuthenticationType(context)

        // Check if the device supports biometric authentication.
        if let biometricAuthType,
           context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometrics are available and enrolled, permissions are undetermined or granted.
            return .authorized(biometricAuthType)
        } else {
            guard let error else {
                return .notDetermined
            }
            return errorStatus(biometricAuthType: biometricAuthType, error: error)
        }
    }

    func getBiometricIntegrityState() -> Data? {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.evaluatedPolicyDomainState
    }

    // MARK: Private Methods

    /// Derives a BiometricAuthStatus from a supplied error.
    ///
    /// - Parameters:
    ///   - biometricAuthType: The biometry type.
    ///   - error: The error to use in constructing an auth status.
    /// - Returns: A BiometricAuthStatus.
    ///
    func errorStatus(
        biometricAuthType: BiometricAuthenticationType?,
        error: Error
    ) -> BiometricAuthorizationStatus {
        guard let biometricAuthType else {
            // Biometrics are not available on the device.
            Logger.application.log("Biometry is not available.")
            return .noBiometrics
        }
        guard let laError = error as? LAError else {
            // A non LAError occured
            Logger.application.log("Other error: \(error.localizedDescription)")
            return .unknownError(error.localizedDescription, biometricAuthType)
        }

        // If canEvaluatePolicy returns false, check the error code.
        switch laError.code {
        case .biometryNotAvailable:
            // The user has denied Biometrics permission for this app.
            Logger.application.log("Biometric permission denied!")
            return .denied(biometricAuthType)
        case .biometryNotEnrolled:
            // Biometrics are supported but not enrolled.
            Logger.application.log("Biometry is supported but not enrolled.")
            return .notEnrolled(biometricAuthType)
        case .biometryLockout:
            // Biometrics are locked out, typically due to too many failed attempts.
            Logger.application.log("Biometry is temporarily locked out.")
            return .lockedOut(biometricAuthType)
        default:
            // Other types of errors.
            Logger.application.log("Other error: \(laError.localizedDescription)")
            return .unknownError(laError.localizedDescription, biometricAuthType)
        }
    }
}
