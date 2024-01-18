import BitwardenSdk

/// A protocol for service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth() -> ClientAuthProtocol

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto() -> ClientCryptoProtocol

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator() -> ClientGeneratorsProtocol

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform() -> ClientPlatformProtocol

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func clientVault() -> ClientVaultService
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
class DefaultClientService: ClientService {
    // MARK: Properties

    /// The `Client` instance used to access `BitwardenSdk`.
    private let client: Client

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameter settings: The settings to apply to the client. Defaults to `nil`.
    ///
    init(settings: ClientSettings? = nil) {
        client = Client(settings: settings)
    }

    // MARK: Methods

    func clientAuth() -> ClientAuthProtocol {
        client.auth()
    }

    func clientCrypto() -> ClientCryptoProtocol {
        client.crypto()
    }

    func clientGenerator() -> ClientGeneratorsProtocol {
        client.generators()
    }

    func clientPlatform() -> ClientPlatformProtocol {
        client.platform()
    }

    func clientVault() -> ClientVaultService {
        client.vault()
    }
}
