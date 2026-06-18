import Foundation

// MARK: - KeyConnectorAPIService

/// A protocol for an API service used to make key connector requests.
///
protocol KeyConnectorAPIService {
    /// Sends the user's master key to the key connector API.
    ///
    /// - Parameters:
    ///   - key: The user's master key.
    ///   - keyConnectorUrl: The base URL of the key connector API.
    ///
    func postMasterKeyToKeyConnector(key: String, keyConnectorUrl: URL) async throws
}

// MARK: - APIService

extension APIService: KeyConnectorAPIService {
    func postMasterKeyToKeyConnector(key: String, keyConnectorUrl: URL) async throws {
        let service = buildKeyConnectorService(baseURL: keyConnectorUrl)
        let body = PostKeyConnectorUserKeyRequestModel(key: key)
        _ = try await service.send(PostKeyConnectorUserKeyRequest(body: body))
    }
}
