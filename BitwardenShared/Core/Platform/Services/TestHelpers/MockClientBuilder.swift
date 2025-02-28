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
    var authClient = MockAuthClient()
    var cryptoClient = MockCryptoClient()
    var exporterClient = MockExporterClient()
    var generatorClient = MockGeneratorClient()
    var platformClient = MockPlatformClientService()
    var sendClient = MockSendClient()
    var vaultClient = MockVaultClientService()

    func auth() -> any AuthClientProtocol {
        authClient
    }

    func crypto() -> CryptoClientProtocol {
        cryptoClient
    }

    func echo(msg: String) -> String {
        ""
    }

    func exporters() -> any ExporterClientProtocol {
        exporterClient
    }

    func generators() -> any GeneratorClientsProtocol {
        generatorClient
    }

    func platform() -> any PlatformClientService {
        platformClient
    }

    func sends() -> any SendClientProtocol {
        sendClient
    }

    func vault() -> any VaultClientService {
        vaultClient
    }
}
