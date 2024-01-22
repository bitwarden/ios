import LocalAuthentication

@testable import BitwardenShared

class MockBiometricsService: BiometricsService {
    var biometricAuthenticationType: BiometricAuthenticationType?
    var biometricAuthStatus: BiometricAuthorizationStatus = .notDetermined
    var biometricIntegrityState: Data?

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
