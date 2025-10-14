import BitwardenSdk

@testable import AuthenticatorShared

class MockCryptoClient: CryptoClientProtocol {
    var deriveKeyConnectorRequest: DeriveKeyConnectorRequest?
    var deriveKeyConnectorResult: Result<String, Error> = .success("key")

    var derivePinKeyPin: String?
    var derivePinUserKey: String?
    var derivePinKeyResult: Result<DerivePinKeyResponse, Error> = .success(
        DerivePinKeyResponse(pinProtectedUserKey: "", encryptedPin: ""),
    )

    var derivePinUserKeyPin: String?
    var derivePinUserKeyResult: Result<EncString, Error> = .success("ENCRYPTED_USER_KEY")

    var encryptedPin: String?

    var enrollAdminPasswordPublicKey: String?
    var enrollAdminPasswordResetResult: Result<String, Error> = .success("RESET_PASSWORD_KEY")

    var enrollPinPin: String?
    var enrollPinResult: Result<EnrollPinResponse, Error> = .success(
        EnrollPinResponse(
            pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
            userKeyEncryptedPin: "userKeyEncryptedPin",
        ),
    )

    var enrollPinWithEncryptedPinEncryptedPin: String?
    var enrollPinWithEncryptedPinResult: Result<EnrollPinResponse, Error> = .success(
        EnrollPinResponse(
            pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
            userKeyEncryptedPin: "userKeyEncryptedPin",
        ),
    )

    var getUserEncryptionKeyResult: Result<String, Error> = .success("USER_ENCRYPTION_KEY")

    var initializeOrgCryptoRequest: InitOrgCryptoRequest?
    var initializeOrgCryptoResult: Result<Void, Error> = .success(())

    var initializeUserCryptoRequest: InitUserCryptoRequest?
    var initializeUserCryptoResult: Result<Void, Error> = .success(())

    var makeUpdateKdfKdf: Kdf?
    var makeUpdateKdfPassword: String?
    var makeUpdateKdfResult: Result<UpdateKdfResponse, Error> = .success(
        UpdateKdfResponse(
            masterPasswordAuthenticationData: MasterPasswordAuthenticationData(
                kdf: .pbkdf2(iterations: NonZeroU32(600_000)),
                salt: "AUTHENTICATION_SALT",
                masterPasswordAuthenticationHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
            ),
            masterPasswordUnlockData: MasterPasswordUnlockData(
                kdf: .pbkdf2(iterations: NonZeroU32(600_000)),
                masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
                salt: "UNLOCK_SALT",
            ),
            oldMasterPasswordAuthenticationData: MasterPasswordAuthenticationData(
                kdf: .pbkdf2(iterations: NonZeroU32(600_000)),
                salt: "OLD_AUTHENTICATION_SALT",
                masterPasswordAuthenticationHash: "MASTER_PASSWORD_AUTHENTICATION_HASH",
            ),
        ),
    )

    var updatePasswordNewPassword: String?
    var updatePasswordResult: Result<UpdatePasswordResponse, Error> = .success(
        UpdatePasswordResponse(
            passwordHash: "password hash",
            newKey: "new key",
        ),
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

    func enrollPin(pin: String) throws -> EnrollPinResponse {
        enrollPinPin = pin
        return try enrollPinResult.get()
    }

    func enrollPinWithEncryptedPin(encryptedPin: EncString) throws -> EnrollPinResponse {
        enrollPinWithEncryptedPinEncryptedPin = encryptedPin
        return try enrollPinWithEncryptedPinResult.get()
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

    func makeUpdateKdf(password: String, kdf: Kdf) throws -> UpdateKdfResponse {
        makeUpdateKdfPassword = password
        makeUpdateKdfKdf = kdf
        return try makeUpdateKdfResult.get()
    }

    func makeUpdatePassword(newPassword: String) throws -> UpdatePasswordResponse {
        updatePasswordNewPassword = newPassword
        return try updatePasswordResult.get()
    }

    func updatePassword(newPassword: String) throws -> BitwardenSdk.UpdatePasswordResponse {
        updatePasswordNewPassword = newPassword
        return try updatePasswordResult.get()
    }
}
