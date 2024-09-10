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
        let isAuthenticated = try? await stateService.isAuthenticated()
        guard isAuthenticated == true else {
            return try await apiUnauthenticatedService.send(ConfigRequest())
        }
        return try await apiService.send(ConfigRequest())
    }
}
