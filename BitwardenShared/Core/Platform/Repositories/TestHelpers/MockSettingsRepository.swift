import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var addedFolderName: String?
    var addFolderResult: Result<Void, Error> = .success(())
    var fetchSyncCalled = false
    var fetchSyncResult: Result<Void, Error> = .success(())
    var foldersListError: Error?
    var isLockedResult: Result<Bool, VaultTimeoutServiceError> = .failure(.noAccountFound)
    var lastSyncTimeError: Error?
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lockVaultCalls = [String?]()
    var unlockVaultCalls = [String?]()
    var logoutResult: Result<Void, StateServiceError> = .failure(.noActiveAccount)
    var foldersListSubject = CurrentValueSubject<[FolderView], Error>([])

    func addFolder(name: String) async throws {
        addedFolderName = name
        try addFolderResult.get()
    }

    func fetchSync() async throws {
        fetchSyncCalled = true
        try fetchSyncResult.get()
    }

    func isLocked(userId _: String) throws -> Bool {
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

    func foldersListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[FolderView], Error>> {
        if let foldersListError {
            throw foldersListError
        }
        return AsyncThrowingPublisher(foldersListSubject.eraseToAnyPublisher())
    }
}
