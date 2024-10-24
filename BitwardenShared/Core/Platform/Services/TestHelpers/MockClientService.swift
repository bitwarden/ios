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
    var mockPlatform: MockClientPlatformService
    var mockSends: MockClientSends
    var mockVault: MockClientVaultService
    var userClientArray = [String: BitwardenSdkClient]()

    init(
        auth: MockClientAuth = MockClientAuth(),
        crypto: MockClientCrypto = MockClientCrypto(),
        exporters: MockClientExporters = MockClientExporters(),
        generators: MockClientGenerators = MockClientGenerators(),
        platform: MockClientPlatformService = MockClientPlatformService(),
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

    func auth(for userId: String?, isPreAuth: Bool) -> ClientAuthProtocol {
        mockAuthIsPreAuth = isPreAuth
        mockAuthUserId = userId
        return mockAuth
    }

    func crypto(for userId: String?) -> ClientCryptoProtocol {
        mockCrypto
    }

    func exporters(for userId: String?) -> ClientExportersProtocol {
        mockExporters
    }

    func generators(for userId: String?, isPreAuth: Bool) -> ClientGeneratorsProtocol {
        mockGeneratorsIsPreAuth = isPreAuth
        mockGeneratorsUserId = userId
        return mockGenerators
    }

    func platform(for userId: String?) -> ClientPlatformService {
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
