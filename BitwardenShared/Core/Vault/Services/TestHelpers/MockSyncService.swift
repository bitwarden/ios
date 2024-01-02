import Combine

@testable import BitwardenShared

class MockSyncService: SyncService {
    var didClearCachedData = false

    var didFetchSync = false
    var fetchSyncResult: Result<Void, Error> = .success(())

    var organizationsToReturn: [ProfileOrganizationResponseModel]?

    var syncSubject = CurrentValueSubject<SyncResponseModel?, Never>(nil)

    func clearCachedData() {
        didClearCachedData = true
    }

    func fetchSync() async throws {
        didFetchSync = true
        try fetchSyncResult.get()
    }

    func organizations() -> [ProfileOrganizationResponseModel]? {
        organizationsToReturn
    }

    func syncResponsePublisher() -> AnyPublisher<BitwardenShared.SyncResponseModel?, Never> {
        syncSubject.eraseToAnyPublisher()
    }
}
