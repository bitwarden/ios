@testable import BitwardenShared

class MockAuthRepository: AuthRepository {
    var logoutCalled = false
    var unlockVaultPassword: String?
    var unlockVaultResult: Result<Void, Error> = .success(())

    func logout() async throws {
        logoutCalled = true
    }

    func unlockVault(password: String) async throws {
        unlockVaultPassword = password
        try unlockVaultResult.get()
    }
}
