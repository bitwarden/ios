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

    /// Returns the managing organization that requires the use of Key Connector for the user.
    ///
    /// - Returns: The managing organization that requires the use of Key Connector for the user.
    ///
    func getManagingOrganization() async throws -> Organization?

    /// Fetches the user's master key from Key Connector.
    ///
    /// - Parameter keyConnectorUrl: The URL to the Key Connector API.
    /// - Returns: The user's master key.
    ///
    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String

    /// Migrates the user to use Key Connector.
    ///
    /// - Parameter password: The user's master password.
    ///
    func migrateUser(password: String) async throws

    /// Returns whether the user needs to be migrated to using Key Connector.
    ///
    /// - Returns: Whether the user needs to be migrated to using Key Connector.
    ///
    func userNeedsMigration() async throws -> Bool
}

// MARK: - KeyConnectorServiceError

/// The errors thrown from a `KeyConnectorService`.
///
enum KeyConnectorServiceError: Error {
    /// The user's encrypted user key is missing.
    case missingEncryptedUserKey

    /// There's no organization found that uses Key Connector.
    case missingOrganization
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

    /// The service for managing the organizations for the user.
    private let organizationService: OrganizationService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The service used to get auth tokens from.
    private let tokenService: TokenService

    // MARK: Initialization

    /// Initialize a `DefaultKeyConnectorService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The service used by the application to make account related API requests.
    ///   - clientService: The service that handles common client functionality such as encryption
    ///     and decryption.
    ///   - keyConnectorAPIService: The API service used to make key connector requests.
    ///   - organizationService: The service for managing the organizations for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - tokenService: The service used to get auth tokens from.
    ///
    init(
        accountAPIService: AccountAPIService,
        clientService: ClientService,
        keyConnectorAPIService: KeyConnectorAPIService,
        organizationService: OrganizationService,
        stateService: StateService,
        tokenService: TokenService
    ) {
        self.accountAPIService = accountAPIService
        self.clientService = clientService
        self.keyConnectorAPIService = keyConnectorAPIService
        self.organizationService = organizationService
        self.stateService = stateService
        self.tokenService = tokenService
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

    func getManagingOrganization() async throws -> Organization? {
        try await organizationService.fetchAllOrganizations()
            .first { $0.keyConnectorEnabled && !$0.isAdmin }
    }

    func getMasterKeyFromKeyConnector(keyConnectorUrl: URL) async throws -> String {
        try await keyConnectorAPIService.getMasterKeyFromKeyConnector(keyConnectorUrl: keyConnectorUrl)
    }

    func migrateUser(password: String) async throws {
        guard let organization = try await getManagingOrganization(),
              let keyConnectorUrlString = organization.keyConnectorUrl,
              let keyConnectorUrl = URL(string: keyConnectorUrlString)
        else {
            throw KeyConnectorServiceError.missingOrganization
        }

        let account = try await stateService.getActiveAccount()
        let encryptionKeys = try await stateService.getAccountEncryptionKeys(userId: account.profile.userId)
        guard let encryptedUserKey = encryptionKeys.encryptedUserKey else {
            throw KeyConnectorServiceError.missingEncryptedUserKey
        }

        let masterKey = try await clientService.crypto().deriveKeyConnector(request: DeriveKeyConnectorRequest(
            userKeyEncrypted: encryptedUserKey,
            password: password,
            kdf: account.kdf.sdkKdf,
            email: account.profile.email
        ))

        try await keyConnectorAPIService.postMasterKeyToKeyConnector(
            key: masterKey,
            keyConnectorUrl: keyConnectorUrl
        )
        try await accountAPIService.convertToKeyConnector()

        try await stateService.setUserHasMasterPassword(false)
    }

    func userNeedsMigration() async throws -> Bool {
        guard try await tokenService.getIsExternal() else {
            return false
        }
        guard try await stateService.getUsesKeyConnector() == false else {
            return false
        }
        return try await getManagingOrganization() != nil
    }
}
