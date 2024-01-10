import BitwardenSdk

@testable import BitwardenShared

class MockClientCrypto: ClientCryptoProtocol {
    var derivePinKeyPin: String?
    var derivePinKeyResult: Result<DerivePinKeyResponse, Error> = .success(
        DerivePinKeyResponse(pinProtectedUserKey: "", encryptedPin: "")
    )

    var getUserEncryptionKeyResult: Result<String, Error> = .success("USER_ENCRYPTION_KEY")

    var initializeOrgCryptoRequest: InitOrgCryptoRequest?
    var initializeOrgCryptoResult: Result<Void, Error> = .success(())

    var initializeUserCryptoRequest: InitUserCryptoRequest?
    var initializeUserCryptoResult: Result<Void, Error> = .success(())

    func derivePinKey(pin: String) async throws -> DerivePinKeyResponse {
        derivePinKeyPin = pin
        return try derivePinKeyResult.get()
    }

    func getUserEncryptionKey() async throws -> String {
        try getUserEncryptionKeyResult.get()
    }

    func initializeOrgCrypto(req: InitOrgCryptoRequest) async throws {
        initializeOrgCryptoRequest = req
        return try initializeOrgCryptoResult.get()
    }

    func initializeUserCrypto(req: InitUserCryptoRequest) async throws {
        initializeUserCryptoRequest = req
        return try initializeUserCryptoResult.get()
    }
}
