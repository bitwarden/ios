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
    var clientPlatform = MockClientPlatformService()
    var clientSends = MockClientSends()
    var clientVault = MockClientVaultService()

    func auth() -> any ClientAuthProtocol {
        clientAuth
    }

    func crypto() -> ClientCryptoProtocol {
        clientCrypto
    }

    func echo(msg: String) -> String {
        ""
    }

    func exporters() -> any ClientExportersProtocol {
        clientExporters
    }

    func generators() -> any ClientGeneratorsProtocol {
        clientGenerators
    }

    func platform() -> any ClientPlatformService {
        clientPlatform
    }

    func sends() -> any ClientSendsProtocol {
        clientSends
    }

    func vault() -> any ClientVaultService {
        clientVault
    }
}
