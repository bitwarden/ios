@testable import BitwardenShared

class MockBiometricsRepository: BiometricsRepository {
    var biometricUnlockStatus: Result<BiometricsUnlockStatus, Error> = .success(.notAvailable)
    var capturedUserAuthKey: String?
    var didDeleteKey: Bool = false
    var getBiometricAuthenticationTypeResult: BitwardenShared.BiometricAuthenticationType?
    var getUserAuthKeyResult: Result<String, Error> = .success("UserAuthKey")
    var setBiometricUnlockKeyError: Error?

    func getBiometricAuthenticationType() -> BitwardenShared.BiometricAuthenticationType? {
        getBiometricAuthenticationTypeResult
    }

    func getBiometricUnlockStatus() async throws -> BitwardenShared.BiometricsUnlockStatus {
        try biometricUnlockStatus.get()
    }

    func getUserAuthKey() async throws -> String {
        try getUserAuthKeyResult.get()
    }

    func setBiometricUnlockKey(authKey: String?) async throws {
        capturedUserAuthKey = authKey
        if let setBiometricUnlockKeyError {
            throw setBiometricUnlockKeyError
        }
    }
}
