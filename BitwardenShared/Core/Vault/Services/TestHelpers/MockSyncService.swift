import Combine

@testable import BitwardenShared

class MockSyncService: SyncService {
    weak var delegate: SyncServiceDelegate?
    var didFetchSync = false
    var fetchSyncForceSync: Bool?
    var fetchSyncIsPeriodic: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    var deleteCipherData: SyncCipherNotification?
    var deleteCipherResult: Result<Void, Error> = .success(())

    var deleteFolderData: SyncFolderNotification?
    var deleteFolderResult: Result<Void, Error> = .success(())

    var deleteSendData: SyncSendNotification?
    var deleteSendResult: Result<Void, Error> = .success(())

    var fetchUpsertSyncCipherData: SyncCipherNotification?
    var fetchUpsertSyncCipherResult: Result<Void, Error> = .success(())

    var fetchUpsertSyncFolderData: SyncFolderNotification?
    var fetchUpsertSyncFolderResult: Result<Void, Error> = .success(())

    var fetchUpsertSyncSendData: SyncSendNotification?
    var fetchUpsertSyncSendResult: Result<Void, Error> = .success(())

    var needsSyncResult: Result<Bool, Error> = .success(false)
    var needsSyncOnlyCheckLocalData: Bool = false

    func fetchSync(forceSync: Bool, isPeriodic: Bool) async throws {
        didFetchSync = true
        fetchSyncForceSync = forceSync
        fetchSyncIsPeriodic = isPeriodic
        try fetchSyncResult.get()
    }

    func deleteCipher(data: SyncCipherNotification) async throws {
        deleteCipherData = data
        return try deleteCipherResult.get()
    }

    func deleteFolder(data: SyncFolderNotification) async throws {
        deleteFolderData = data
        return try deleteFolderResult.get()
    }

    func deleteSend(data: SyncSendNotification) async throws {
        deleteSendData = data
        return try deleteSendResult.get()
    }

    func fetchUpsertSyncCipher(data: SyncCipherNotification) async throws {
        fetchUpsertSyncCipherData = data
        return try fetchUpsertSyncCipherResult.get()
    }

    func fetchUpsertSyncFolder(data: SyncFolderNotification) async throws {
        fetchUpsertSyncFolderData = data
        return try fetchUpsertSyncFolderResult.get()
    }

    func fetchUpsertSyncSend(data: SyncSendNotification) async throws {
        fetchUpsertSyncSendData = data
        return try fetchUpsertSyncSendResult.get()
    }

    func needsSync(for userId: String, onlyCheckLocalData: Bool) async throws -> Bool {
        needsSyncOnlyCheckLocalData = onlyCheckLocalData
        return try needsSyncResult.get()
    }
}
