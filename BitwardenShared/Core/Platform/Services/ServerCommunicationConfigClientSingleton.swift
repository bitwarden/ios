import BitwardenKit
import BitwardenSdk

/// A singleton for `ServerCommunicationConfigClientProtocol`. Needed to break circular dependency.
protocol ServerCommunicationConfigClientSingleton {
    /// Returns a `ServerCommunicationConfigClientProtocol` for server communication configuration.
    /// - Returns: A `ServerCommunicationConfigClientProtocol` for server communication.
    func client() async throws -> ServerCommunicationConfigClientProtocol
}

/// Default implementation of `ServerCommunicationConfigClientSingleton`.
final class DefaultServerCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton {
    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService

    /// The factory to create SDK repositories.
    private let sdkRepositoryFactory: SdkRepositoryFactory

    /// The server communication configuration client.
    private var serverCommunicationConfigClient: ServerCommunicationConfigClientProtocol?
    
    /// Initializes a `DefaultServerCommunicationConfigClientSingleton`.
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - sdkRepositoryFactory: The factory to create SDK repositories.
    init(
        clientService: ClientService,
        sdkRepositoryFactory: SdkRepositoryFactory,
    ) {
        self.clientService = clientService
        self.sdkRepositoryFactory = sdkRepositoryFactory
    }

    func client() async throws -> ServerCommunicationConfigClientProtocol {
        if let serverCommunicationConfigClient {
            return serverCommunicationConfigClient
        }

        // This server communication client can be created using any SDK client
        // as it depends on the objects we're passing.
        let serverConfigClient = try await clientService.platform().serverCommunicationConfig(
            repository: sdkRepositoryFactory.makeServerCommunicationConfigRepository(),
            platformApi: ServerCommunicationConfigAPIService()
        )
        serverCommunicationConfigClient = serverConfigClient
        return serverConfigClient
    }
}
