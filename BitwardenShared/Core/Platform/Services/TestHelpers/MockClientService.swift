import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var clientAuthService: MockClientAuth
    var clientCryptoService: MockClientCrypto
    var clientExportersService: MockClientExporters
    var clientGeneratorService: MockClientGenerators
    var clientPlatformService: MockClientPlatform
    var clientVaultService: MockClientVaultService
    var userClientDictionary = [String: (client: BitwardenSdk.Client, isUnlocked: Bool)]()

    init(
        clientAuth: MockClientAuth = MockClientAuth(),
        clientCrypto: MockClientCrypto = MockClientCrypto(),
        clientExporters: MockClientExporters = MockClientExporters(),
        clientGenerators: MockClientGenerators = MockClientGenerators(),
        clientPlatform: MockClientPlatform = MockClientPlatform(),
        clientVault: MockClientVaultService = MockClientVaultService()
    ) {
        clientAuthService = clientAuth
        clientCryptoService = clientCrypto
        clientExportersService = clientExporters
        clientGeneratorService = clientGenerators
        clientPlatformService = clientPlatform
        clientVaultService = clientVault
    }

    func clientAuth(for userId: String?) -> ClientAuthProtocol {
        clientAuthService
    }

    func clientCrypto(for userId: String?) -> ClientCryptoProtocol {
        clientCryptoService
    }

    func clientExporters(for userId: String?) -> ClientExportersProtocol {
        clientExportersService
    }

    func clientGenerator(for userId: String?) -> ClientGeneratorsProtocol {
        clientGeneratorService
    }

    func clientPlatform(for userId: String?) -> ClientPlatformProtocol {
        clientPlatformService
    }

    func clientVault(for userId: String?) -> ClientVaultService {
        clientVaultService
    }
}
