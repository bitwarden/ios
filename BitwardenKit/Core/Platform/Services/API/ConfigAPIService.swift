/// A protocol for an API service used to make config requests.
///
public protocol ConfigAPIService {
    /// Performs an API request to get the configuration from the backend.
    ///
    func getConfig() async throws -> ConfigResponseModel
}
