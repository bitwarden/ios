import BitwardenSdk
import Foundation

// MARK: - KeyConnectorService

/// A protocol for a `KeyConnectorService` which manages Key Connector.
///
protocol KeyConnectorService {
    /// Converts a new user without an existing encryption key to using Key Connector.
    ///
    /// - Parameters:
    ///   - keyConnectorUrl: The URL to the Key Connector API.
    ///   - orgIdentifier: The text identifier for the organization.
    ///
    func convertNewUserToKeyConnector(
        keyConnectorUrl: URL,
        orgIdentifier: String
    ) async throws

    /// Fetches the user's master key from Key Connector.
    ///
    /// - Parameter keyConnectorUrl: The URL to the Key Connector API.
    /// - Returns: The user's master key.
    ///
    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String
}

// MARK: - DefaultKeyConnectorService

/// A default implementation of `KeyConnectorService`.
///
class DefaultKeyConnectorService {
    // MARK: Properties

    /// The service used by the application to make account related API requests.
    private let accountAPIService: AccountAPIService

    /// The service that handles common client functionality such as encryption and decryption.
    private let clientService: ClientService

    /// The API service used to make key connector requests.
    private let keyConnectorAPIService: KeyConnectorAPIService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultKeyConnectorService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The service used by the application to make account related API requests.
    ///   - clientService: The service that handles common client functionality such as encryption
    ///     and decryption.
    ///   - keyConnectorAPIService: The API service used to make key connector requests.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        accountAPIService: AccountAPIService,
        clientService: ClientService,
        keyConnectorAPIService: KeyConnectorAPIService,
        stateService: StateService
    ) {
        self.accountAPIService = accountAPIService
        self.clientService = clientService
        self.keyConnectorAPIService = keyConnectorAPIService
        self.stateService = stateService
    }
}

extension DefaultKeyConnectorService: KeyConnectorService {
    func convertNewUserToKeyConnector(keyConnectorUrl: URL, orgIdentifier: String) async throws {
        let keyConnectorResponse = try await clientService.auth().makeKeyConnectorKeys()

        try await keyConnectorAPIService.postMasterKeyToKeyConnector(
            key: keyConnectorResponse.masterKey,
            keyConnectorUrl: keyConnectorUrl
        )

        let account = try await stateService.getActiveAccount()
        try await accountAPIService.setKeyConnectorKey(
            SetKeyConnectorKeyRequestModel(
                kdfConfig: account.kdf,
                key: keyConnectorResponse.encryptedUserKey,
                keys: KeysRequestModel(keyPair: keyConnectorResponse.keys),
                orgIdentifier: orgIdentifier
            )
        )

        try await stateService.setAccountEncryptionKeys(
            AccountEncryptionKeys(
                encryptedPrivateKey: keyConnectorResponse.keys.private,
                encryptedUserKey: keyConnectorResponse.encryptedUserKey
            )
        )
    }

    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String {
        try await keyConnectorAPIService.getMasterKeyFromKeyConnector(keyConnectorUrl: keyConnectorUrl)
    }
}
