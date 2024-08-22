import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockClientAuth: ClientAuthProtocol {
    var approveAuthRequestPublicKey: String?
    var approveAuthRequestResult: Result<AsymmetricEncString, Error> = .success("")

    var hashPasswordEmail: String?
    var hashPasswordPassword: String?
    var hashPasswordKdfParams: Kdf?
    var hashPasswordPurpose: HashPurpose?
    var hashPasswordResult: Result<String, Error> = .success("hash password")

    var makeKeyConnectorKeysCalled = false
    var makeKeyConnectorKeysResult: Result<KeyConnectorResponse, Error> = .success(
        KeyConnectorResponse(
            masterKey: "masterKey",
            encryptedUserKey: "encryptedUserKey",
            keys: RsaKeyPair(public: "public", private: "private")
        )
    )

    var makeRegisterKeysEmail: String?
    var makeRegisterKeysPassword: String?
    var makeRegisterKeysKdf: Kdf?
    var makeRegisterKeysResult: Result<RegisterKeyResponse, Error> = .success(RegisterKeyResponse(
        masterPasswordHash: "masterPasswordHash",
        encryptedUserKey: "encryptedUserKey",
        keys: RsaKeyPair(public: "public", private: "private")
    ))

    var makeRegisterTdeKeysEmail: String?
    var makeRegisterTdeKeysOrgPublicKey: String?
    var makeRegisterTdeKeysRememberDevice: Bool?
    var makeRegisterTdeKeysResult: Result<RegisterTdeKeyResponse, Error> = .success(
        RegisterTdeKeyResponse(
            privateKey: "privateKey",
            publicKey: "publicKey",
            adminReset: "adminReset",
            deviceKey: TrustDeviceResponse(
                deviceKey: "deviceKey",
                protectedUserKey: "protectedUserKey",
                protectedDevicePrivateKey: "protectedDevicePrivateKey",
                protectedDevicePublicKey: "protectedDevicePublicKey"
            )
        )
    )

    var newAuthRequestEmail: String?
    var newAuthRequestResult: Result<AuthRequestResponse, Error> = .success(
        AuthRequestResponse(
            privateKey: "private",
            publicKey: "public",
            fingerprint: "fingerprint",
            accessCode: "12345"
        )
    )
    var passwordStrengthResult = UInt8(2)
    var passwordStrengthPassword: String?
    var passwordStrengthEmail: String?
    var passwordStrengthAdditionalInputs: [String]?

    var satisfiesPolicyPassword: String?
    var satisfiesPolicyStrength: UInt8?
    var satisfiesPolicyPolicy: MasterPasswordPolicyOptions?
    var satisfiesPolicyResult = true

    var validatePasswordPassword: String?
    var validatePasswordPasswordHash: String?
    var validatePasswordResult: Bool = false

    var validatePasswordUserKeyEncryptedUserKey: String?
    var validatePasswordUserKeyPassword: String?
    var validatePasswordUserKeyResult: Result<String, Error> = .success("MASTER_PASSWORD_HASH")

    var validatePinResult: Result<Bool, Error> = .success(false)

    var trustDeviceResult: Result<TrustDeviceResponse, Error> = .success(
        TrustDeviceResponse(
            deviceKey: "DEVICE_KEY",
            protectedUserKey: "USER_KEY",
            protectedDevicePrivateKey: "DEVICE_PRIVATE_KEY",
            protectedDevicePublicKey: "DEVICE_PUBLIC_KEY"
        )
    )

    func approveAuthRequest(publicKey: String) throws -> AsymmetricEncString {
        approveAuthRequestPublicKey = publicKey
        return try approveAuthRequestResult.get()
    }

    func hashPassword(email: String, password: String, kdfParams: Kdf, purpose: HashPurpose) async throws -> String {
        hashPasswordEmail = email
        hashPasswordPassword = password
        hashPasswordKdfParams = kdfParams
        hashPasswordPurpose = purpose

        return try hashPasswordResult.get()
    }

    func makeKeyConnectorKeys() throws -> KeyConnectorResponse {
        makeKeyConnectorKeysCalled = true
        return try makeKeyConnectorKeysResult.get()
    }

    func makeRegisterKeys(email: String, password: String, kdf: Kdf) throws -> RegisterKeyResponse {
        makeRegisterKeysEmail = email
        makeRegisterKeysPassword = password
        makeRegisterKeysKdf = kdf

        return try makeRegisterKeysResult.get()
    }

    func makeRegisterTdeKeys(
        email: String,
        orgPublicKey: String,
        rememberDevice: Bool
    ) throws -> BitwardenSdk.RegisterTdeKeyResponse {
        makeRegisterTdeKeysEmail = email
        makeRegisterTdeKeysOrgPublicKey = orgPublicKey
        makeRegisterTdeKeysRememberDevice = rememberDevice
        return try makeRegisterTdeKeysResult.get()
    }

    func newAuthRequest(email: String) throws -> AuthRequestResponse {
        newAuthRequestEmail = email
        return try newAuthRequestResult.get()
    }

    func passwordStrength(password: String, email: String, additionalInputs: [String]) -> UInt8 {
        passwordStrengthPassword = password
        passwordStrengthEmail = email
        passwordStrengthAdditionalInputs = additionalInputs

        return passwordStrengthResult
    }

    func satisfiesPolicy(password: String, strength: UInt8, policy: MasterPasswordPolicyOptions) -> Bool {
        satisfiesPolicyPassword = password
        satisfiesPolicyStrength = strength
        satisfiesPolicyPolicy = policy

        return satisfiesPolicyResult
    }

    func trustDevice() throws -> BitwardenSdk.TrustDeviceResponse {
        try trustDeviceResult.get()
    }

    func validatePassword(password: String, passwordHash: String) throws -> Bool {
        validatePasswordPassword = password
        validatePasswordPasswordHash = passwordHash
        return validatePasswordResult
    }

    func validatePasswordUserKey(password: String, encryptedUserKey: String) throws -> String {
        validatePasswordUserKeyPassword = password
        validatePasswordUserKeyEncryptedUserKey = encryptedUserKey
        return try validatePasswordUserKeyResult.get()
    }

    func validatePin(pin: String, pinProtectedUserKey: BitwardenSdk.EncString) throws -> Bool {
        try validatePinResult.get()
    }
}
