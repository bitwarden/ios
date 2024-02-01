import Combine

@testable import BitwardenShared

class MockSyncService: SyncService {
    var didFetchSync = false
    var fetchSyncForceSync: Bool?
    var fetchSyncResult: Result<Void, Error> = .success(())

    func fetchSync(forceSync: Bool) async throws {
        didFetchSync = true
        fetchSyncForceSync = forceSync
        try fetchSyncResult.get()
    }
}
