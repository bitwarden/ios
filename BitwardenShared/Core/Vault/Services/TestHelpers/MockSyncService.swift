import Combine

@testable import BitwardenShared

class MockSyncService: SyncService {
    var didFetchSync = false
    var fetchSyncResult: Result<Void, Error> = .success(())

    func fetchSync() async throws {
        didFetchSync = true
        try fetchSyncResult.get()
    }
}
