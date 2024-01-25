import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockClientAuth: ClientAuthProtocol {
    var approveAuthRequestResult: Result<String, Error> = .success("asymmetricEncString")
    var hashPasswordResult: Result<String, Error> = .success("hash password")
    var makeRegisterKeysResult: Result<RegisterKeyResponse, Error> = .success(RegisterKeyResponse(
        masterPasswordHash: "masterPasswordHash",
        encryptedUserKey: "encryptedUserKey",
        keys: RsaKeyPair(public: "public", private: "private")
    ))

    var hashPasswordEmail: String?
    var hashPasswordPassword: String?
    var hashPasswordKdfParams: Kdf?
    var hashPasswordPurpose: HashPurpose?

    var makeRegisterKeysEmail: String?
    var makeRegisterKeysPassword: String?
    var makeRegisterKeysKdf: Kdf?

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

    func approveAuthRequest(publicKey: String) async throws -> AsymmetricEncString {
        try approveAuthRequestResult.get()
    }

    func hashPassword(email: String, password: String, kdfParams: Kdf, purpose: HashPurpose) async throws -> String {
        hashPasswordEmail = email
        hashPasswordPassword = password
        hashPasswordKdfParams = kdfParams
        hashPasswordPurpose = purpose

        return try hashPasswordResult.get()
    }

    func makeRegisterKeys(email: String, password: String, kdf: Kdf) async throws -> RegisterKeyResponse {
        makeRegisterKeysEmail = email
        makeRegisterKeysPassword = password
        makeRegisterKeysKdf = kdf

        return try makeRegisterKeysResult.get()
    }

    func newAuthRequest(email: String) async throws -> AuthRequestResponse {
        try newAuthRequestResult.get()
    }

    func passwordStrength(password: String, email: String, additionalInputs: [String]) async -> UInt8 {
        passwordStrengthPassword = password
        passwordStrengthEmail = email
        passwordStrengthAdditionalInputs = additionalInputs

        return passwordStrengthResult
    }

    func satisfiesPolicy(password: String, strength: UInt8, policy: MasterPasswordPolicyOptions) async -> Bool {
        satisfiesPolicyPassword = password
        satisfiesPolicyStrength = strength
        satisfiesPolicyPolicy = policy

        return satisfiesPolicyResult
    }

    func validatePassword(password: String, passwordHash: String) async throws -> Bool {
        validatePasswordPassword = password
        validatePasswordPasswordHash = passwordHash
        return validatePasswordResult
    }
}
