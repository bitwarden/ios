import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var mockAuth: MockClientAuth
    var mockCrypto: MockClientCrypto
    var mockExporters: MockClientExporters
    var mockGenerators: MockClientGenerators
    var mockPlatform: MockClientPlatform
    var mockSends: MockClientSends
    var mockVault: MockClientVaultService
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockClientAuth = MockClientAuth(),
        crypto: MockClientCrypto = MockClientCrypto(),
        exporters: MockClientExporters = MockClientExporters(),
        generators: MockClientGenerators = MockClientGenerators(),
        platform: MockClientPlatform = MockClientPlatform(),
        sends: MockClientSends = MockClientSends(),
        vault: MockClientVaultService = MockClientVaultService()
    ) {
        mockAuth = auth
        mockCrypto = crypto
        mockExporters = exporters
        mockGenerators = generators
        mockPlatform = platform
        mockSends = sends
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

    func removeClient(for userId: String?) async throws {
        guard let userId else { return }
        userClientArray.removeValue(forKey: userId)
    }

    func sends(for userId: String?) -> ClientSendsProtocol {
        mockSends
    }

    func vault(for userId: String?) -> ClientVaultService {
        mockVault
    }
}
