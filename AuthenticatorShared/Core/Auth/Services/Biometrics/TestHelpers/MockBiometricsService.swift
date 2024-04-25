import LocalAuthentication

@testable import AuthenticatorShared

class MockBiometricsService: BiometricsService {
    var biometricAuthenticationType: BiometricAuthenticationType?
    var biometricAuthStatus: BiometricAuthorizationStatus = .notDetermined
    var biometricIntegrityState: Data?
    var evaluationResult: Bool = true

    func evaluateBiometricPolicy(
        _ suppliedContext: LAContext?,
        for biometricAuthStatus: BiometricAuthorizationStatus
    ) async -> Bool {
        evaluationResult
    }

    func getBiometricAuthenticationType(_ suppliedContext: LAContext?) -> BiometricAuthenticationType? {
        biometricAuthenticationType
    }

    func getBiometricAuthStatus() -> BiometricAuthorizationStatus {
        biometricAuthStatus
    }

    func getBiometricIntegrityState() -> Data? {
        biometricIntegrityState
    }
}
