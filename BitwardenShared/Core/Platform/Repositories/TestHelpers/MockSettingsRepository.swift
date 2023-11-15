@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var isLockedResult: Result<Bool, VaultTimeoutServiceError> = .failure(.noAccountFound)
    var lockVaultCalled: (Bool, String)?
    var logoutResult: Result<Void, StateServiceError> = .failure(.noActiveAccount)

    func isLocked(userId: String) throws -> Bool {
        try isLockedResult.get()
    }

    func lockVault(_ shouldLock: Bool, userId: String) {
        lockVaultCalled = (shouldLock, userId)
    }

    func logout() async throws {
        try logoutResult.get()
    }
}
