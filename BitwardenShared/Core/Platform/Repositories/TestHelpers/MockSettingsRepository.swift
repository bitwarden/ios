@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var isLockedResult: Result<Bool, VaultTimeoutServiceError> = .failure(.noAccountFound)
    var lockVaultCalls = [String?]()
    var unlockVaultCalls = [String?]()
    var logoutResult: Result<Void, StateServiceError> = .failure(.noActiveAccount)

    func isLocked(userId: String) throws -> Bool {
        try isLockedResult.get()
    }

    func lockVault(userId: String?) {
        lockVaultCalls.append(userId)
    }

    func unlockVault(userId: String?) {
        lockVaultCalls.append(userId)
    }

    func logout() async throws {
        try logoutResult.get()
    }
}
