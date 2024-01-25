import BitwardenSdk
import Combine
import Foundation

@testable import BitwardenShared

class MockSettingsRepository: SettingsRepository {
    var addedFolderName: String?
    var addFolderResult: Result<Void, Error> = .success(())
    var allowSyncOnRefresh = false
    var allowSyncOnRefreshResult: Result<Void, Error> = .success(())
    var connectToWatch = false
    var connectToWatchResult: Result<Void, Error> = .success(())
    var deletedFolderId: String?
    var deleteFolderResult: Result<Void, Error> = .success(())
    var editedFolderName: String?
    var editFolderResult: Result<Void, Error> = .success(())
    var fetchSyncCalled = false
    var fetchSyncResult: Result<Void, Error> = .success(())
    var foldersListError: Error?
    var getDefaultUriMatchTypeResult: Result<BitwardenShared.UriMatchType, Error> = .success(.domain)
    var getDisableAutoTotpCopyResult: Result<Bool, Error> = .success(false)
    var lastSyncTimeError: Error?
    var lastSyncTimeSubject = CurrentValueSubject<Date?, Never>(nil)
    var updateDefaultUriMatchTypeValue: BitwardenShared.UriMatchType?
    var updateDefaultUriMatchTypeResult: Result<Void, Error> = .success(())
    var updateDisableAutoTotpCopyValue: Bool?
    var updateDisableAutoTotpCopyResult: Result<Void, Error> = .success(())
    var validatePasswordPasswords = [String]()
    var validatePasswordResult: Result<Bool, Error> = .success(true)
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

    func getConnectToWatch() async throws -> Bool {
        try connectToWatchResult.get()
        return connectToWatch
    }

    func getDefaultUriMatchType() async throws -> BitwardenShared.UriMatchType {
        try getDefaultUriMatchTypeResult.get()
    }

    func getDisableAutoTotpCopy() async throws -> Bool {
        try getDisableAutoTotpCopyResult.get()
    }

    func lastSyncTimePublisher() async throws -> AsyncPublisher<AnyPublisher<Date?, Never>> {
        if let lastSyncTimeError {
            throw lastSyncTimeError
        }
        return lastSyncTimeSubject.eraseToAnyPublisher().values
    }

    func updateAllowSyncOnRefresh(_ allowSyncOnRefresh: Bool) async throws {
        self.allowSyncOnRefresh = allowSyncOnRefresh
        try allowSyncOnRefreshResult.get()
    }

    func updateConnectToWatch(_ connectToWatch: Bool) async throws {
        self.connectToWatch = connectToWatch
        try connectToWatchResult.get()
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

    func foldersListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[FolderView], Error>> {
        if let foldersListError {
            throw foldersListError
        }
        return AsyncThrowingPublisher(foldersListSubject.eraseToAnyPublisher())
    }
}
