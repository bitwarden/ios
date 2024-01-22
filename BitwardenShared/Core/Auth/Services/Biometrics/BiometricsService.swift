import LocalAuthentication
import OSLog

// MARK: - BiometricsService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsService: AnyObject {
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

class DefaultBiometricsService: BiometricsService {
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
            guard let biometricAuthType else {
                // Biometrics are not available on the device.
                Logger.application.log("Biometry is not available.")
                return .noBiometrics
            }
            guard let laError = error as? LAError else {
                // A non LAError occured
                Logger.application.log("Other error: \(error?.localizedDescription ?? "")")
                return .unknownError(error?.localizedDescription ?? "", biometricAuthType)
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

    func getBiometricIntegrityState() -> Data? {
        let context = LAContext()
        var error: NSError?
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return context.evaluatedPolicyDomainState
    }
}
