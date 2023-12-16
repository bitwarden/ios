import Combine
import Foundation

@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var fetchSyncCalled = false
    var fetchSyncResult: Result<Void, Error> = .success(())
    var isLockedResult: Result<Bool, VaultTimeoutServiceError> = .failure(.noAccountFound)
    var lastSyncTimeError: Error?
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lockVaultCalls = [String?]()
    var unlockVaultCalls = [String?]()
    var logoutResult: Result<Void, StateServiceError> = .failure(.noActiveAccount)

    func fetchSync() async throws {
        fetchSyncCalled = true
        try fetchSyncResult.get()
    }

    func isLocked(userId: String) throws -> Bool {
        try isLockedResult.get()
    }

    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>> {
        if let lastSyncTimeError {
            throw lastSyncTimeError
        }
        return lastSyncTimeSubject.eraseToAnyPublisher().values
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
