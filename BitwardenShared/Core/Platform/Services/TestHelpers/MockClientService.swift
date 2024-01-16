import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var clientAuthService: MockClientAuth
    var clientPlatformService: MockClientPlatform
    var clientVaultService: MockClientVaultService

    init(
        clientAuth: MockClientAuth = MockClientAuth(),
        clientPlatform: MockClientPlatform = MockClientPlatform(),
        clientVault: MockClientVaultService = MockClientVaultService()
    ) {
        clientAuthService = clientAuth
        clientPlatformService = clientPlatform
        clientVaultService = clientVault
    }

    func clientAuth() -> ClientAuthProtocol {
        clientAuthService
    }

    func clientCrypto() -> ClientCryptoProtocol {
        fatalError("Not implemented yet")
    }

    func clientGenerator() -> ClientGeneratorsProtocol {
        fatalError("Not implemented yet")
    }

    func clientPlatform() -> ClientPlatformProtocol {
        clientPlatformService
    }

    func clientVault() -> ClientVaultService {
        clientVaultService
    }
}
