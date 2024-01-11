@testable import BitwardenShared

class MockBiometricsService: BiometricsService {
    var biometricAuthStatus: BiometricAuthorizationStatus = .noBiometrics
    var capturedUserAuthKey: String?
    var capturedUserID: String?
    var deleteResult: Result<Void, Error> = .success(())
    var didDeleteKey: Bool = false
    var retrieveUserAuthKeyResult: Result<String, Error> = .success("UserAuthKey")
    var setUserAuthKeyError: Error?

    func deleteUserAuthKey(for userId: String) async throws {
        capturedUserID = userId
        try deleteResult.get()
        didDeleteKey = true
    }

    func getBiometricAuthStatus() -> BitwardenShared.BiometricAuthorizationStatus {
        biometricAuthStatus
    }

    func retrieveUserAuthKey(for userId: String) async throws -> String? {
        capturedUserID = userId
        return try retrieveUserAuthKeyResult.get()
    }

    func setUserAuthKey(value: String, for userId: String) async throws {
        capturedUserAuthKey = value
        capturedUserID = userId
        if let setUserAuthKeyError {
            throw setUserAuthKeyError
        }
    }
}
