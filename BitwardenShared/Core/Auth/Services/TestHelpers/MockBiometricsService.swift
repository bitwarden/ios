import LocalAuthentication

@testable import BitwardenShared

class MockBiometricsService: BiometricsService {
    var biometricAuthenticationType: BiometricAuthenticationType?
    var biometricAuthStatus: BiometricAuthorizationStatus = .notDetermined
    var evaluationResult: Bool = true

    func evaluateBiometricPolicy(
        _ suppliedContext: LAContext?,
        for biometricAuthStatus: BitwardenShared.BiometricAuthorizationStatus
    ) async -> Bool {
        evaluationResult
    }

    func getBiometricAuthenticationType(_ suppliedContext: LAContext?) -> BiometricAuthenticationType? {
        biometricAuthenticationType
    }

    func getBiometricAuthStatus() -> BiometricAuthorizationStatus {
        biometricAuthStatus
    }
}
