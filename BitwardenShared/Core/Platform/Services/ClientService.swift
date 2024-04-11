import BitwardenSdk

/// A protocol for service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    var userClientDictionary: [String?: Client] { get set }

    func createClientForUser(userId: String)

    func clientForUser(userId: String) async throws -> Client?

    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth(for userId: String?) async throws -> ClientAuthProtocol

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto(for userId: String?) async throws -> ClientCryptoProtocol

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    func clientExporters(for userId: String?) async throws -> ClientExportersProtocol

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator(for userId: String?) async throws -> ClientGeneratorsProtocol

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform(for userId: String?) async throws -> ClientPlatformProtocol

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func clientVault(for userId: String?) async throws -> ClientVaultService
}

extension ClientService {
    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth() async throws -> ClientAuthProtocol {
        try await clientAuth(for: nil)
    }

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto() async throws -> ClientCryptoProtocol {
        try await clientCrypto(for: nil)
    }

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    func clientExporters() async throws -> ClientExportersProtocol {
        try await clientExporters(for: nil)
    }

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator() async throws -> ClientGeneratorsProtocol {
        try await clientGenerator(for: nil)
    }

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform() async throws -> ClientPlatformProtocol {
        try await clientPlatform(for: nil)
    }

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func clientVault() async throws -> ClientVaultService {
        try await clientVault(for: nil)
    }
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
class DefaultClientService: ClientService {
    var userClientDictionary = [String?: Client]()

    // MARK: Properties

    private let stateService: StateService

    private let client: Client

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameter settings: The settings to apply to the client. Defaults to `nil`.
    ///
    init(stateService: StateService) {
        client = Client(settings: nil)
        self.stateService = stateService
    }

    // MARK: Methods

    func clientAuth(for userId: String?) async throws -> ClientAuthProtocol {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.auth()
    }

    func clientCrypto(for userId: String?) async throws -> ClientCryptoProtocol {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.crypto()
    }

    func clientExporters(for userId: String?) async throws -> ClientExportersProtocol {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.exporters()
    }

    func clientGenerator(for userId: String?) async throws -> ClientGeneratorsProtocol {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.generators()
    }

    func clientPlatform(for userId: String?) async throws -> ClientPlatformProtocol {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.platform()
    }

    func clientVault(for userId: String?) async throws -> ClientVaultService {
        let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
        let client = clientForUser(userId: userId) ?? client
        return client.vault()
    }

    func clientForUser(userId: String) -> Client? {
        for _ in userClientDictionary {
            if let client = userClientDictionary[userId] {
                return client
            }
        }
        return nil
    }

    func createClientForUser(userId: String) {
        let client = Client(settings: nil)
        userClientDictionary.updateValue(client, forKey: userId)
    }
}
