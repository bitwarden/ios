@testable import BitwardenShared

class MockBiometricsRepository: BiometricsRepository {
    var getBiometricAuthenticationTypeResult: BitwardenShared.BiometricAuthenticationType?

    var biometricUnlockStatus: Result<BiometricsUnlockStatus, Error>?
    var getBiometricUnlockStatusError: Error?
    var getBiometricUnlockStatusActiveUser = BiometricsUnlockStatus.notAvailable
    var getBiometricUnlockStatusByUserId = [String: BiometricsUnlockStatus]()

    var getUserAuthKeyResult: Result<String, Error> = .success("UserAuthKey")

    var setBiometricUnlockKeyActiveUser: String?
    var setBiometricUnlockKeyByUserId = [String: String]()
    var setBiometricUnlockKeyError: Error?

    func getBiometricAuthenticationType() -> BitwardenShared.BiometricAuthenticationType? {
        getBiometricAuthenticationTypeResult
    }

    func getBiometricUnlockStatus(userId: String?) async throws -> BitwardenShared.BiometricsUnlockStatus {
        if let getBiometricUnlockStatusError {
            throw getBiometricUnlockStatusError
        }
        if let biometricUnlockStatus {
            // TODO: PM-31189 Legacy mock value, update all tests to use getBiometricUnlockStatusByUserId
            return try biometricUnlockStatus.get()
        }
        guard let userId else {
            return getBiometricUnlockStatusActiveUser
        }
        return getBiometricUnlockStatusByUserId[userId] ?? .notAvailable
    }

    func getUserAuthKey() async throws -> String {
        try getUserAuthKeyResult.get()
    }

    func setBiometricUnlockKey(authKey: String?, userId: String?) async throws {
        if let setBiometricUnlockKeyError { throw setBiometricUnlockKeyError }
        guard let userId else {
            setBiometricUnlockKeyActiveUser = authKey
            return
        }
        setBiometricUnlockKeyByUserId[userId] = authKey
    }
}
