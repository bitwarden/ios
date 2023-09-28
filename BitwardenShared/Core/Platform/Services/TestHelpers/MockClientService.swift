import BitwardenSdk

@testable import BitwardenShared

class MockClientService: ClientService {
    var clientAuthService: MockClientAuth
    var clientVaultService: MockClientVaultService

    init(
        clientAuth: MockClientAuth = MockClientAuth(),
        clientVault: MockClientVaultService = MockClientVaultService()
    ) {
        clientAuthService = clientAuth
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

    func clientVault() -> ClientVaultService {
        clientVaultService
    }
}
