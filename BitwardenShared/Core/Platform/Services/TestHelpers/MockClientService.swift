import BitwardenSdk
import BitwardenSdkMocks

@testable import BitwardenShared

class MockClientService: ClientService {
    var mockAuth: MockAuthClient
    var mockAuthIsPreAuth = false
    var mockAuthUserId: String?
    var mockCrypto: MockCryptoClient
    var mockExporters: MockExporterClient
    var mockGenerators: MockGeneratorClientsProtocol
    var mockGeneratorsIsPreAuth = false
    var mockGeneratorsUserId: String?
    var mockPlatform: MockPlatformClientService
    var mockPlatformIsPreAuth = false
    var mockSends: MockSendClientProtocol
    var mockVault: MockVaultClientService
    var platformCallCount = 0
    var platformError: Error?
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockAuthClient = MockAuthClient(),
        crypto: MockCryptoClient = MockCryptoClient(),
        exporters: MockExporterClient = MockExporterClient(),
        generators: MockGeneratorClientsProtocol = MockGeneratorClientsProtocol(),
        platform: MockPlatformClientService = MockPlatformClientService(),
        sends: MockSendClientProtocol = {
            let mock = MockSendClientProtocol()
            mock.decryptClosure = { SendView(send: $0) }
            mock.encryptClosure = { Send(sendView: $0) }
            mock.encryptBufferClosure = { _, buffer in buffer }
            return mock
        }(),
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

    func platform(for userId: String?, isPreAuth: Bool) throws -> PlatformClientService {
        platformCallCount += 1
        if let platformError {
            throw platformError
        }
        mockPlatformIsPreAuth = isPreAuth
        return mockPlatform
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
