import BitwardenSdk

@testable import BitwardenShared

class MockCryptoClient: CryptoClientProtocol {
    var deriveKeyConnectorRequest: DeriveKeyConnectorRequest?
    var deriveKeyConnectorResult: Result<String, Error> = .success("key")

    var derivePinKeyPin: String?
    var derivePinUserKey: String?
    var derivePinKeyResult: Result<DerivePinKeyResponse, Error> = .success(
        DerivePinKeyResponse(pinProtectedUserKey: "", encryptedPin: "")
    )

    var derivePinUserKeyPin: String?
    var derivePinUserKeyResult: Result<EncString, Error> = .success("ENCRYPTED_USER_KEY")

    var encryptedPin: String?

    var enrollAdminPasswordPublicKey: String?
    var enrollAdminPasswordResetResult: Result<String, Error> = .success("RESET_PASSWORD_KEY")

    var getUserEncryptionKeyCalled = false
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

    func deriveKeyConnector(request: DeriveKeyConnectorRequest) throws -> String {
        deriveKeyConnectorRequest = request
        return try deriveKeyConnectorResult.get()
    }

    func derivePinKey(pin: String) throws -> DerivePinKeyResponse {
        derivePinKeyPin = pin
        return try derivePinKeyResult.get()
    }

    func derivePinUserKey(encryptedPin: EncString) throws -> EncString {
        try derivePinUserKeyResult.get()
    }

    func enrollAdminPasswordReset(publicKey: String) throws -> UnsignedSharedKey {
        enrollAdminPasswordPublicKey = publicKey
        return try enrollAdminPasswordResetResult.get()
    }

    func getUserEncryptionKey() async throws -> String {
        getUserEncryptionKeyCalled = true
        return try getUserEncryptionKeyResult.get()
    }

    func initializeOrgCrypto(req: InitOrgCryptoRequest) async throws {
        initializeOrgCryptoRequest = req
        return try initializeOrgCryptoResult.get()
    }

    func initializeUserCrypto(req: InitUserCryptoRequest) async throws {
        initializeUserCryptoRequest = req
        return try initializeUserCryptoResult.get()
    }

    func updatePassword(newPassword: String) throws -> BitwardenSdk.UpdatePasswordResponse {
        updatePasswordNewPassword = newPassword
        return try updatePasswordResult.get()
    }
}
