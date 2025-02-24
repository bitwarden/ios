@testable import AuthenticatorShared

class MockBiometricsRepository: BiometricsRepository {
    var biometricUnlockStatus: Result<BiometricsUnlockStatus, Error> = .success(.notAvailable)
    var capturedUserAuthKey: String?
    var didConfigureBiometricIntegrity = false
    var didDeleteKey: Bool = false
    var getUserAuthKeyResult: Result<String, Error> = .success("UserAuthKey")
    var setBiometricUnlockKeyError: Error?

    func configureBiometricIntegrity() async {
        didConfigureBiometricIntegrity = true
    }

    func getBiometricUnlockStatus() async throws -> BiometricsUnlockStatus {
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
