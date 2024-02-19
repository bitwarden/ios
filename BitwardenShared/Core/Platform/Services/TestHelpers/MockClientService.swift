import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var clientAuthService: MockClientAuth
    var clientExportersService: MockClientExporters
    var clientPlatformService: MockClientPlatform
    var clientVaultService: MockClientVaultService

    init(
        clientAuth: MockClientAuth = MockClientAuth(),
        clientExporters: MockClientExporters = MockClientExporters(),
        clientPlatform: MockClientPlatform = MockClientPlatform(),
        clientVault: MockClientVaultService = MockClientVaultService()
    ) {
        clientAuthService = clientAuth
        clientExportersService = clientExporters
        clientPlatformService = clientPlatform
        clientVaultService = clientVault
    }

    func clientAuth() -> ClientAuthProtocol {
        clientAuthService
    }

    func clientCrypto() -> ClientCryptoProtocol {
        fatalError("Not implemented yet")
    }

    func clientExporters() -> BitwardenSdk.ClientExportersProtocol {
        clientExportersService
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
