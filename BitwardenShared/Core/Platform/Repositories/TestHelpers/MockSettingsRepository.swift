import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var addedFolderName: String?
    var addFolderResult: Result<Void, Error> = .success(())
    var allowSyncOnRefresh = false
    var allowSyncOnRefreshResult: Result<Void, Error> = .success(())
    var deletedFolderId: String?
    var deleteFolderResult: Result<Void, Error> = .success(())
    var editedFolderName: String?
    var editFolderResult: Result<Void, Error> = .success(())
    var fetchSyncCalled = false
    var fetchSyncResult: Result<Void, Error> = .success(())
    var foldersListError: Error?
    var getDefaultUriMatchTypeResult: Result<BitwardenShared.UriMatchType, Error> = .success(.domain)
    var getDisableAutoTotpCopyResult: Result<Bool, Error> = .success(false)
    var isLockedResult: Result<Bool, VaultTimeoutServiceError> = .failure(.noAccountFound)
    var lastSyncTimeError: Error?
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var lockVaultCalls = [String?]()
    var unlockVaultCalls = [String?]()
    var updateDefaultUriMatchTypeValue: BitwardenShared.UriMatchType?
    var updateDefaultUriMatchTypeResult: Result<Void, Error> = .success(())
    var updateDisableAutoTotpCopyValue: Bool?
    var updateDisableAutoTotpCopyResult: Result<Void, Error> = .success(())
    var validatePasswordPasswords = [String]()
    var validatePasswordResult: Result<Bool, Error> = .success(true)
    var logoutResult: Result<Void, StateServiceError> = .failure(.noActiveAccount)
    var foldersListSubject = CurrentValueSubject<[FolderView], Error>([])

    var clearClipboardValue: ClearClipboardValue = .never

    func addFolder(name: String) async throws {
        addedFolderName = name
        try addFolderResult.get()
    }

    func deleteFolder(id: String) async throws {
        deletedFolderId = id
        try deleteFolderResult.get()
    }

    func editFolder(withID _: String, name: String) async throws {
        editedFolderName = name
        try editFolderResult.get()
    }

    func fetchSync() async throws {
        fetchSyncCalled = true
        try fetchSyncResult.get()
    }

    func getAllowSyncOnRefresh() async throws -> Bool {
        try allowSyncOnRefreshResult.get()
        return allowSyncOnRefresh
    }

    func getDefaultUriMatchType() async throws -> BitwardenShared.UriMatchType {
        try getDefaultUriMatchTypeResult.get()
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try getDisableAutoTotpCopyResult.get()
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

    func updateAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws {
        self.allowSyncOnRefresh = allowSyncOnRefresh
        try allowSyncOnRefreshResult.get()
    }

    func updateDefaultUriMatchType(_ defaultUriMatchType: BitwardenShared.UriMatchType) async throws {
        updateDefaultUriMatchTypeValue = defaultUriMatchType
        try updateDefaultUriMatchTypeResult.get()
    }

    func updateDisableAutoTotpCopy(_ disableAutoTotpCopy: Bool) async throws {
        updateDisableAutoTotpCopyValue = disableAutoTotpCopy
        try updateDisableAutoTotpCopyResult.get()
    }

    func validatePassword(_ password: String) async throws -> Bool {
        validatePasswordPasswords.append(password)
        return try validatePasswordResult.get()
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
