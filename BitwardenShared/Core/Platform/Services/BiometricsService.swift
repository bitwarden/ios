import LocalAuthentication
import OSLog

// MARK: - BiometricsService

/// A protocol for returning the available authentication policies and access controls for the user's device.
///
protocol BiometricsService: AnyObject {
    /// Returns the available authentication policies and access controls for the user's device.
    ///
    /// - Returns: Available authentication policies and access controls for the user's device.
    ///
    func getBiometricAuthenticationType() -> BiometricAuthenticationType
}

// MARK: - DefaultBiometricsService

/// A default implementation of `BiometricsService`, which returns the available authentication policies and access controls for the user's device,
/// and logs an error if one occurs while obtaining the device's biometric authentication type.
///
class DefaultBiometricsService: BiometricsService {
    func getBiometricAuthenticationType() -> BiometricAuthenticationType {
        let authContext = LAContext()
        var error: NSError?

        guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            Logger.processor.error("Error checking biometrics type: \(error)")
            return .none
        }

        switch authContext.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        @unknown default:
            return .none
        }
    }
}
