import Foundation

// swiftlint:disable inclusive_language

// MARK: - KeyConnectorAPIService

/// A protocol for an API service used to make key connector requests.
///
protocol KeyConnectorAPIService {
    /// Gets the user's master key from the key connector API.
    ///
    /// - Parameter keyConnectorUrl: The base URL of the key connector API.
    /// - Returns: The user's master key.
    ///
    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String

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
    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String {
        let service = buildKeyConnectorService(baseURL: keyConnectorUrl)
        let response = try await service.send(KeyConnectorUserKeyRequest())
        return response.key
    }

    func postMasterKeyToKeyConnector(key: String, keyConnectorUrl: URL) async throws {
        let service = buildKeyConnectorService(baseURL: keyConnectorUrl)
        let body = PostKeyConnectorUserKeyRequestModel(key: key)
        _ = try await service.send(PostKeyConnectorUserKeyRequest(body: body))
    }
}

// swiftlint:enable inclusive_language
