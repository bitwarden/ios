import BitwardenKit
import BitwardenSdk
import BitwardenSdkMocks
import Foundation

public class MockAuthClient: AuthClientService {
    public var approveAuthRequestPublicKey: String?
    public var approveAuthRequestResult: Result<UnsignedSharedKey, Error> = .success("")

    public var clientRegistration = MockRegistrationClientProtocol()

    public var hashPasswordEmail: String?
    public var hashPasswordPassword: String?
    public var hashPasswordKdfParams: Kdf?
    public var hashPasswordPurpose: HashPurpose?
    public var hashPasswordResult: Result<String, Error> = .success("hash password")

    public var makeKeyConnectorKeysCalled = false
    public var makeKeyConnectorKeysResult: Result<KeyConnectorResponse, Error> = .success(
        KeyConnectorResponse(
            masterKey: "masterKey",
            encryptedUserKey: "encryptedUserKey",
            keys: RsaKeyPair(public: "public", private: "private"),
        ),
    )

    public var makeRegisterKeysEmail: String?
    public var makeRegisterKeysPassword: String?
    public var makeRegisterKeysKdf: Kdf?
    public var makeRegisterKeysResult: Result<RegisterKeyResponse, Error> = .success(RegisterKeyResponse(
        masterPasswordHash: "masterPasswordHash",
        encryptedUserKey: "encryptedUserKey",
        keys: RsaKeyPair(public: "public", private: "private"),
    ))

    public var makeRegisterTdeKeysEmail: String?
    public var makeRegisterTdeKeysOrgPublicKey: String?
    public var makeRegisterTdeKeysRememberDevice: Bool?
    public var makeRegisterTdeKeysResult: Result<RegisterTdeKeyResponse, Error> = .success(
        RegisterTdeKeyResponse(
            privateKey: "privateKey",
            publicKey: "publicKey",
            adminReset: "adminReset",
            deviceKey: TrustDeviceResponse(
                deviceKey: "deviceKey",
                protectedUserKey: "protectedUserKey",
                protectedDevicePrivateKey: "protectedDevicePrivateKey",
                protectedDevicePublicKey: "protectedDevicePublicKey",
            ),
        ),
    )

    public var newAuthRequestEmail: String?
    public var newAuthRequestResult: Result<AuthRequestResponse, Error> = .success(
        AuthRequestResponse(
            privateKey: "private",
            publicKey: "public",
            fingerprint: "fingerprint",
            accessCode: "12345",
        ),
    )
    public var passwordStrengthResult = UInt8(2)
    public var passwordStrengthPassword: String?
    public var passwordStrengthEmail: String?
    public var passwordStrengthAdditionalInputs: [String]?

    public var satisfiesPolicyPassword: String?
    public var satisfiesPolicyStrength: UInt8?
    public var satisfiesPolicyPolicy: MasterPasswordPolicyOptions?
    public var satisfiesPolicyResult = true

    public var validatePasswordPassword: String?
    public var validatePasswordPasswordHash: String?
    public var validatePasswordResult: Bool = false

    public var validatePasswordUserKeyEncryptedUserKey: String?
    public var validatePasswordUserKeyPassword: String?
    public var validatePasswordUserKeyResult: Result<String, Error> = .success("MASTER_PASSWORD_HASH")

    public var validatePinResult: Result<Bool, Error> = .success(false)

    public var validatePinProtectedUserKeyEnvelopePin: String?
    public var validatePinProtectedUserKeyEnvelopePinProtectedUserKeyEnvelope: PasswordProtectedKeyEnvelope? // swiftlint:disable:this identifier_name line_length
    public var validatePinProtectedUserKeyEnvelopeResult: Bool = true // swiftlint:disable:this identifier_name

    public var trustDeviceResult: Result<TrustDeviceResponse, Error> = .success(
        TrustDeviceResponse(
            deviceKey: "DEVICE_KEY",
            protectedUserKey: "USER_KEY",
            protectedDevicePrivateKey: "DEVICE_PRIVATE_KEY",
            protectedDevicePublicKey: "DEVICE_PUBLIC_KEY",
        ),
    )

    public init() {}

    public func approveAuthRequest(publicKey: String) throws -> UnsignedSharedKey {
        approveAuthRequestPublicKey = publicKey
        return try approveAuthRequestResult.get()
    }

    public func hashPassword(
        email: String,
        password: String,
        kdfParams: Kdf,
        purpose: HashPurpose,
    ) async throws -> String {
        hashPasswordEmail = email
        hashPasswordPassword = password
        hashPasswordKdfParams = kdfParams
        hashPasswordPurpose = purpose

        return try hashPasswordResult.get()
    }

    public func makeKeyConnectorKeys() throws -> KeyConnectorResponse {
        makeKeyConnectorKeysCalled = true
        return try makeKeyConnectorKeysResult.get()
    }

    public func makeRegisterKeys(email: String, password: String, kdf: Kdf) throws -> RegisterKeyResponse {
        makeRegisterKeysEmail = email
        makeRegisterKeysPassword = password
        makeRegisterKeysKdf = kdf

        return try makeRegisterKeysResult.get()
    }

    public func makeRegisterTdeKeys(
        email: String,
        orgPublicKey: String,
        rememberDevice: Bool,
    ) throws -> BitwardenSdk.RegisterTdeKeyResponse {
        makeRegisterTdeKeysEmail = email
        makeRegisterTdeKeysOrgPublicKey = orgPublicKey
        makeRegisterTdeKeysRememberDevice = rememberDevice
        return try makeRegisterTdeKeysResult.get()
    }

    public func newAuthRequest(email: String) throws -> AuthRequestResponse {
        newAuthRequestEmail = email
        return try newAuthRequestResult.get()
    }

    public func passwordStrength(password: String, email: String, additionalInputs: [String]) -> UInt8 {
        passwordStrengthPassword = password
        passwordStrengthEmail = email
        passwordStrengthAdditionalInputs = additionalInputs

        return passwordStrengthResult
    }

    public func registration() -> RegistrationClientProtocol {
        clientRegistration
    }

    public func satisfiesPolicy(password: String, strength: UInt8, policy: MasterPasswordPolicyOptions) -> Bool {
        satisfiesPolicyPassword = password
        satisfiesPolicyStrength = strength
        satisfiesPolicyPolicy = policy

        return satisfiesPolicyResult
    }

    public func trustDevice() throws -> BitwardenSdk.TrustDeviceResponse {
        try trustDeviceResult.get()
    }

    public func validatePassword(password: String, passwordHash: String) throws -> Bool {
        validatePasswordPassword = password
        validatePasswordPasswordHash = passwordHash
        return validatePasswordResult
    }

    public func validatePasswordUserKey(password: String, encryptedUserKey: String) throws -> String {
        validatePasswordUserKeyPassword = password
        validatePasswordUserKeyEncryptedUserKey = encryptedUserKey
        return try validatePasswordUserKeyResult.get()
    }

    public func validatePin(pin: String, pinProtectedUserKey: BitwardenSdk.EncString) throws -> Bool {
        try validatePinResult.get()
    }

    public func validatePinProtectedUserKeyEnvelope(
        pin: String,
        pinProtectedUserKeyEnvelope: PasswordProtectedKeyEnvelope,
    ) -> Bool {
        validatePinProtectedUserKeyEnvelopePin = pin
        validatePinProtectedUserKeyEnvelopePinProtectedUserKeyEnvelope = pinProtectedUserKeyEnvelope
        return validatePinProtectedUserKeyEnvelopeResult
    }
}
