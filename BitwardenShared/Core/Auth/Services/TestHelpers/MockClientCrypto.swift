import BitwardenSdk

@testable import BitwardenShared

class MockClientCrypto: ClientCryptoProtocol {
    var initializeCryptoRequest: InitCryptoRequest?
    var initializeCryptoResult: Result<Void, Error> = .success(())

    func initializeCrypto(req: InitCryptoRequest) async throws {
        initializeCryptoRequest = req
        return try initializeCryptoResult.get()
    }
}
