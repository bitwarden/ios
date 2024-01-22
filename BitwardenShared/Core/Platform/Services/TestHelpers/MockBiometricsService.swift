@testable import BitwardenShared

class MockBiometricsService: BiometricsService {
    var biometricUnlockStatus: Result<BiometricsUnlockStatus, Error> = .success(.notAvailable)
    var capturedUserAuthKey: String?
    var capturedUserID: String?
    var didConfigureBiometricIntegrity = false
    var didDeleteKey: Bool = false
    var getUserAuthKeyResult: Result<String, Error> = .success("UserAuthKey")
    var setBiometricUnlockKeyError: Error?

    func configureBiometricIntegrity() async {
        didConfigureBiometricIntegrity = true
    }

    func getBiometricUnlockStatus() async throws -> BitwardenShared.BiometricsUnlockStatus {
        try biometricUnlockStatus.get()
    }

    func getUserAuthKey(for userId: String?) async throws -> String {
        capturedUserID = userId
        return try getUserAuthKeyResult.get()
    }

    func setBiometricUnlockKey(authKey: String?, for userId: String?) async throws {
        capturedUserAuthKey = authKey
        capturedUserID = userId
        if let setBiometricUnlockKeyError {
            throw setBiometricUnlockKeyError
        }
    }
}
