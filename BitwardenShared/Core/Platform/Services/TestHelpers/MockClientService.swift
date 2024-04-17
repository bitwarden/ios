import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var mockAuth: MockClientAuth
    var mockCrypto: MockClientCrypto
    var mockExporters: MockClientExporters
    var mockGenerators: MockClientGenerators
    var mockPlatform: MockClientPlatform
    var mockVault: MockClientVaultService
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockClientAuth = MockClientAuth(),
        crypto: MockClientCrypto = MockClientCrypto(),
        exporters: MockClientExporters = MockClientExporters(),
        generators: MockClientGenerators = MockClientGenerators(),
        platform: MockClientPlatform = MockClientPlatform(),
        vault: MockClientVaultService = MockClientVaultService()
    ) {
        mockAuth = auth
        mockCrypto = crypto
        mockExporters = exporters
        mockGenerators = generators
        mockPlatform = platform
        mockVault = vault
    }

    func auth(for userId: String?) -> ClientAuthProtocol {
        mockAuth
    }

    func crypto(for userId: String?) -> ClientCryptoProtocol {
        mockCrypto
    }

    func exporters(for userId: String?) -> ClientExportersProtocol {
        mockExporters
    }

    func generators(for userId: String?) -> ClientGeneratorsProtocol {
        mockGenerators
    }

    func platform(for userId: String?) -> ClientPlatformProtocol {
        mockPlatform
    }

    func vault(for userId: String?) -> ClientVaultService {
        mockVault
    }
}
