import BitwardenSdk

@testable import AuthenticatorShared

class MockClientService: ClientService {
    var mockAuth: MockAuthClient
    var mockAuthIsPreAuth = false
    var mockAuthUserId: String?
    var mockCrypto: MockCryptoClient
    var mockExporters: MockExporterClient
    var mockGenerators: MockGeneratorClient
    var mockGeneratorsIsPreAuth = false
    var mockGeneratorsUserId: String?
    var mockPlatform: MockPlatformClientService
    var mockSends: MockSendClient
    var mockVault: MockVaultClientService
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockAuthClient = MockAuthClient(),
        crypto: MockCryptoClient = MockCryptoClient(),
        exporters: MockExporterClient = MockExporterClient(),
        generators: MockGeneratorClient = MockGeneratorClient(),
        platform: MockPlatformClientService = MockPlatformClientService(),
        sends: MockSendClient = MockSendClient(),
        vault: MockVaultClientService = MockVaultClientService(),
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
