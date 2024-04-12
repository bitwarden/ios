import BitwardenSdk

/// A protocol for service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    // MARK: Properties

    /// A dictionary mapping a user ID to their `Client` and the client's locked status.
    var userClientDictionary: [String: (client: Client, isUnlocked: Bool)] { get set }

    // MARK: Methods

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

    /// Returns a user's `Client` if one exists. If a user doesn't have a client, one is created and
    /// mapped to their user ID in the `userClientDictionary`.
    ///
    /// - Parameter userId: The user ID for which a client belongs to/will belong to.
    /// - Returns: The user's client and its locked status.
    ///
    func userClient(userId: String) async throws -> (client: Client, isUnlocked: Bool)
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
    // MARK: Properties

    var userClientDictionary = [String: (client: Client, isUnlocked: Bool)]()

    // MARK: Private properties

    private let errorReporter: ErrorReporter

    private let settings: ClientSettings?

    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameter settings: The settings to apply to the client. Defaults to `nil`.
    ///
    init(
        errorReporter: ErrorReporter,
        settings: ClientSettings? = nil,
        stateService: StateService
    ) {
        self.errorReporter = errorReporter
        self.settings = settings
        self.stateService = stateService
    }

    // MARK: Methods

    func clientAuth(for userId: String?) async throws -> ClientAuthProtocol {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.auth()
        } catch StateServiceError.noAccounts {
            return newClient().auth()
        }
    }

    func clientCrypto(for userId: String?) async throws -> ClientCryptoProtocol {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.crypto()
        } catch StateServiceError.noAccounts {
            return newClient().crypto()
        }
    }

    func clientExporters(for userId: String?) async throws -> ClientExportersProtocol {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.exporters()
        } catch StateServiceError.noAccounts {
            return newClient().exporters()
        }
    }

    func clientGenerator(for userId: String?) async throws -> ClientGeneratorsProtocol {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.generators()
        } catch StateServiceError.noAccounts {
            return newClient().generators()
        }
    }

    func clientPlatform(for userId: String?) async throws -> ClientPlatformProtocol {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.platform()
        } catch StateServiceError.noAccounts {
            return newClient().platform()
        }
    }

    func clientVault(for userId: String?) async throws -> ClientVaultService {
        do {
            let userId = try await stateService.getAccountIdOrActiveId(userId: userId)
            return await userClient(userId: userId).client.vault()
        } catch StateServiceError.noAccounts {
            return newClient().vault()
        }
    }

    func userClient(userId: String) async -> (client: Client, isUnlocked: Bool) {
        for _ in userClientDictionary {
            if let client = userClientDictionary[userId] {
                await loadFlags(client: client.client)
                return client
            }
        }
        let client = Client(settings: settings)
        await loadFlags(client: client)
        userClientDictionary.updateValue((client, false), forKey: userId)
        return (client, false)
    }

    // MARK: Private methods

    private func newClient() -> Client {
        Client(settings: settings)
    }

    /// Loads feature flags.
    ///
    private func loadFlags(client: Client) async {
        do {
            try await client.platform().loadFlags(
                flags: [FeatureFlagsConstants.enableCipherKeyEncryption: true]
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}
