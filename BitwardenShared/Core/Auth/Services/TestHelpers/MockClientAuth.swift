import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockClientAuth: ClientAuthProtocol {
    var hashPasswordResult: Result<String, Error> = .success("hash password")
    var makeRegisterKeysResult: Result<RegisterKeyResponse, Error> = .success(RegisterKeyResponse(
        masterPasswordHash: "masterPasswordHash",
        encryptedUserKey: "encryptedUserKey",
        keys: RsaKeyPair(public: "public", private: "private")
    ))
    var satisfiesPolicyResult = true
    var passwordStrengthResult = UInt8(2)

    var hashPasswordEmail: String?
    var hashPasswordPassword: String?
    var hashPasswordKdfParams: Kdf?

    var makeRegisterKeysEmail: String?
    var makeRegisterKeysPassword: String?
    var makeRegisterKeysKdf: Kdf?

    var passwordStrengthPassword: String?
    var passwordStrengthEmail: String?
    var passwordStrengthAdditionalInputs: [String]?

    var satisfiesPolicyPassword: String?
    var satisfiesPolicyStrength: UInt8?
    var satisfiesPolicyPolicy: MasterPasswordPolicyOptions?

    func hashPassword(email: String, password: String, kdfParams: Kdf) async throws -> String {
        hashPasswordEmail = email
        hashPasswordPassword = password
        hashPasswordKdfParams = kdfParams

        return try hashPasswordResult.get()
    }

    func makeRegisterKeys(email: String, password: String, kdf: Kdf) async throws -> RegisterKeyResponse {
        makeRegisterKeysEmail = email
        makeRegisterKeysPassword = password
        makeRegisterKeysKdf = kdf

        return try makeRegisterKeysResult.get()
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
}
