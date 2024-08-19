import Foundation

// MARK: - KeyConnectorService

/// A protocol for a `KeyConnectorService` which manages Key Connector.
///
protocol KeyConnectorService {
    /// Fetches the user's master key from Key Connector.
    ///
    /// - Returns: The user's master key.
    ///
    func getMasterKeyFromKeyConnector() async throws -> String
}

// MARK: - KeyConnectorServiceError

/// The errors thrown from a `KeyConnectorService`.
///
enum KeyConnectorServiceError: Error {
    /// The key connector URL doesn't exist for the user.
    case missingKeyConnectorUrl
}

// MARK: - DefaultKeyConnectorService

/// A default implementation of `KeyConnectorService`.
///
class DefaultKeyConnectorService {
    // MARK: Properties

    /// The API service used to make key connector requests.
    private let keyConnectorAPIService: KeyConnectorAPIService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultKeyConnectorService`.
    ///
    /// - Parameters:
    ///   - keyConnectorAPIService: The API service used to make key connector requests.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        keyConnectorAPIService: KeyConnectorAPIService,
        stateService: StateService
    ) {
        self.keyConnectorAPIService = keyConnectorAPIService
        self.stateService = stateService
    }
}

extension DefaultKeyConnectorService: KeyConnectorService {
    func getMasterKeyFromKeyConnector() async throws -> String {
        let account = try await stateService.getActiveAccount()
        let keyConnectorUrlString = account.profile.userDecryptionOptions?.keyConnectorOption?.keyConnectorUrl
        guard let keyConnectorUrlString,
              let keyConnectorUrl = URL(string: keyConnectorUrlString) else {
            throw KeyConnectorServiceError.missingKeyConnectorUrl
        }

        return try await keyConnectorAPIService.getMasterKeyFromKeyConnector(keyConnectorUrl: keyConnectorUrl)
    }
}
