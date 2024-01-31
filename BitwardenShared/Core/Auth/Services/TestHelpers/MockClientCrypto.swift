import BitwardenSdk

@testable import BitwardenShared

class MockClientCrypto: ClientCryptoProtocol {
    var derivePinKeyPin: String?
    var derivePinUserKey: String?
    var derivePinKeyResult: Result<DerivePinKeyResponse, Error> = .success(
        DerivePinKeyResponse(pinProtectedUserKey: "", encryptedPin: "")
    )

    var derivePinUserKeyPin: String?
    var derivePinUserKeyResult: Result<EncString, Error> = .success("ENCRYPTED_USER_KEY")

    var encryptedPin: String?

    var getUserEncryptionKeyResult: Result<String, Error> = .success("USER_ENCRYPTION_KEY")

    var initializeOrgCryptoRequest: InitOrgCryptoRequest?
    var initializeOrgCryptoResult: Result<Void, Error> = .success(())

    var initializeUserCryptoRequest: InitUserCryptoRequest?
    var initializeUserCryptoResult: Result<Void, Error> = .success(())

    var updatePasswordNewPassword: String?
    var updatePasswordResult: Result<UpdatePasswordResponse, Error> = .success(
        UpdatePasswordResponse(
            passwordHash: "password hash",
            newKey: "new key"
        )
    )

    func derivePinKey(pin: String) async throws -> DerivePinKeyResponse {
        derivePinKeyPin = pin
        return try derivePinKeyResult.get()
    }

    func derivePinUserKey(encryptedPin: EncString) async throws -> EncString {
        try derivePinUserKeyResult.get()
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

    func updatePassword(newPassword: String) async throws -> BitwardenSdk.UpdatePasswordResponse {
        updatePasswordNewPassword = newPassword
        return try updatePasswordResult.get()
    }
}
