@testable import BitwardenShared

class MockBiometricsService: BiometricsService {
    var biometricsType: BiometricAuthenticationType = .none

    func getBiometricAuthenticationType() -> BiometricAuthenticationType {
        biometricsType = .faceID
        return biometricsType
    }
}
