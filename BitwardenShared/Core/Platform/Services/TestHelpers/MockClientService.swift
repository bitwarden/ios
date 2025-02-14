import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var mockAuth: MockClientAuth
    var mockAuthIsPreAuth = false
    var mockAuthUserId: String?
    var mockCrypto: MockClientCrypto
    var mockExporters: MockClientExporters
    var mockGenerators: MockClientGenerators
    var mockGeneratorsIsPreAuth = false
    var mockGeneratorsUserId: String?
    var mockPlatform: MockPlatformClientService
    var mockSends: MockClientSends
    var mockVault: MockVaultClientService
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockClientAuth = MockClientAuth(),
        crypto: MockClientCrypto = MockClientCrypto(),
        exporters: MockClientExporters = MockClientExporters(),
        generators: MockClientGenerators = MockClientGenerators(),
        platform: MockPlatformClientService = MockPlatformClientService(),
        sends: MockClientSends = MockClientSends(),
        vault: MockVaultClientService = MockVaultClientService()
    ) {
        mockAuth = auth
        mockCrypto = crypto
        mockExporters = exporters
        mockGenerators = generators
        mockPlatform = platform
        mockSends = sends
        mockVault = vault
    }

    func auth(for userId: String?, isPreAuth: Bool) -> AuthClientProtocol {
        mockAuthIsPreAuth = isPreAuth
        mockAuthUserId = userId
        return mockAuth
    }

    func crypto(for userId: String?) -> CryptoClientProtocol {
        mockCrypto
    }

    func exporters(for userId: String?) -> ExporterClientProtocol {
        mockExporters
    }

    func generators(for userId: String?, isPreAuth: Bool) -> GeneratorClientsProtocol {
        mockGeneratorsIsPreAuth = isPreAuth
        mockGeneratorsUserId = userId
        return mockGenerators
    }

    func platform(for userId: String?) -> PlatformClientService {
        mockPlatform
    }

    func removeClient(for userId: String?) async throws {
        guard let userId else { return }
        userClientArray.removeValue(forKey: userId)
    }

    func sends(for userId: String?) -> SendClientProtocol {
        mockSends
    }

    func vault(for userId: String?) -> VaultClientService {
        mockVault
    }
}
