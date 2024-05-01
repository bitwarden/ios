import Networking

/// A protocol for an API service used to make config requests.
///
protocol ConfigAPIService {
    /// Performs an API request to get the configuration from the backend.
    ///
    func getConfig() async throws -> ConfigResponseModel
}

extension APIService: ConfigAPIService {
    func getConfig() async throws -> ConfigResponseModel {
        try await apiUnauthenticatedService.send(ConfigRequest())
    }
}
