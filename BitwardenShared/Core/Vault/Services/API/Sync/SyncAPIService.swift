/// A protocol for an API service used to make sync requests.
///
protocol SyncAPIService {
    /// Performs the sync request and returns response.
    ///
    /// - Returns: The sync response.
    func getSync() async throws -> SyncResponseModel
}

extension APIService: SyncAPIService {
    func getSync() async throws -> SyncResponseModel {
        try await apiService.send(SyncRequest())
    }
}
