import BitwardenSdk

/// A protocol for service that handles common client functionality such as encryption and
/// decryption.
///
protocol ClientService {
    var userClientArray: [[String?: Client]] { get }

    func assignUserClient(userId: String)

    func clientForUser(userId: String) -> Client

    /// Returns a `ClientAuthProtocol` for auth data tasks.
    ///
    func clientAuth(for userId: String) -> ClientAuthProtocol

    /// Returns a `ClientCryptoProtocol` for crypto data tasks.
    ///
    func clientCrypto(for userId: String) -> ClientCryptoProtocol

    /// Returns a `ClientExportersProtocol` for vault export data tasks.
    ///
    func clientExporters(for userId: String) -> ClientExportersProtocol

    /// Returns a `ClientGeneratorsProtocol` for generator data tasks.
    ///
    func clientGenerator(for userId: String) -> ClientGeneratorsProtocol

    /// Returns a `ClientPlatformProtocol` for client platform tasks.
    ///
    func clientPlatform(for userId: String) -> ClientPlatformProtocol

    /// Returns a `ClientVaultService` for vault data tasks.
    ///
    func clientVault(for userId: String) -> ClientVaultService
}

// MARK: - DefaultClientService

/// A default `ClientService` implementation. This is a thin wrapper around the SDK `Client` so that
/// it can be swapped to a mock instance during tests.
///
class DefaultClientService: ClientService {
    // MARK: Properties

    /// The `Client` instance used to access `BitwardenSdk`.
    private let client: Client

    var userClientArray = [[String?: Client]]()

    // MARK: Initialization

    /// Initialize a `DefaultClientService`.
    ///
    /// - Parameter settings: The settings to apply to the client. Defaults to `nil`.
    ///
    init(settings: ClientSettings? = nil) {
        client = Client(settings: settings)
    }

    // MARK: Methods

    func assignUserClient(userId: String) {
        userClientArray.append([userId: client])
    }

    func clientForUser(userId: String) -> Client {
        for dictionary in userClientArray {
            for (id, client) in dictionary {
                if let id, id == userId {
                    return client
                }
            }
        }
        return client
    }

    func clientAuth(for userId: String) -> ClientAuthProtocol {
        clientForUser(userId: userId).auth()
    }

    func clientCrypto(for userId: String) -> ClientCryptoProtocol {
        clientForUser(userId: userId).crypto()
    }

    func clientExporters(for userId: String) -> ClientExportersProtocol {
        clientForUser(userId: userId).exporters()
    }

    func clientGenerator(for userId: String) -> ClientGeneratorsProtocol {
        clientForUser(userId: userId).generators()
    }

    func clientPlatform(for userId: String) -> ClientPlatformProtocol {
        clientForUser(userId: userId).platform()
    }

    func clientVault(for userId: String) -> ClientVaultService {
        clientForUser(userId: userId).vault()
    }
}
