import BitwardenSdk

@testable import BitwardenShared

final class MockClientBuilder: ClientBuilder {
    var clients = [MockClient]()
    var setupClientOnCreation: ((MockClient) -> Void)?

    func buildClient() -> BitwardenSdkClient {
        let client = MockClient()
        if let setupClientOnCreation {
            setupClientOnCreation(client)
        }
        clients.append(client)
        return client
    }
}

class MockClient: BitwardenSdkClient {
    var clientAuth = MockClientAuth()
    var clientCrypto = MockClientCrypto()
    var clientExporters = MockClientExporters()
    var clientGenerators = MockClientGenerators()
    var clientPlatform = MockPlatformClientService()
    var clientSends = MockClientSends()
    var clientVault = MockVaultClientService()

    func auth() -> any AuthClientProtocol {
        clientAuth
    }

    func crypto() -> CryptoClientProtocol {
        clientCrypto
    }

    func echo(msg: String) -> String {
        ""
    }

    func exporters() -> any ExporterClientProtocol {
        clientExporters
    }

    func generators() -> any GeneratorClientsProtocol {
        clientGenerators
    }

    func platform() -> any PlatformClientService {
        clientPlatform
    }

    func sends() -> any SendClientProtocol {
        clientSends
    }

    func vault() -> any VaultClientService {
        clientVault
    }
}
