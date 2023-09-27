@testable import BitwardenShared

extension IdentityTokenResponseModel {
    static func fixture(
        forcePasswordReset: Bool = false,
        kdf: KdfType = .pbkdf2sha256,
        kdfIterations: Int = 600_000,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil,
        key: String = "KEY",
        masterPasswordPolicy: MasterPasswordPolicyResponseModel? = nil,
        privateKey: String = "PRIVATE_KEY",
        resetMasterPassword: Bool = false,
        userDecryptionOptions: UserDecryptionOptions? = UserDecryptionOptions(
            hasMasterPassword: true,
            keyConnectorOption: nil,
            trustedDeviceOption: nil
        ),
        accessToken: String = "ACCESS_TOKEN",
        expiresIn: Int = 3600,
        tokenType: String = "Bearer",
        refreshToken: String = "REFRESH_TOKEN"
    ) -> IdentityTokenResponseModel {
        IdentityTokenResponseModel(
            forcePasswordReset: forcePasswordReset,
            kdf: kdf,
            kdfIterations: kdfIterations,
            kdfMemory: kdfMemory,
            kdfParallelism: kdfParallelism,
            key: key,
            masterPasswordPolicy: masterPasswordPolicy,
            privateKey: privateKey,
            resetMasterPassword: resetMasterPassword,
            userDecryptionOptions: userDecryptionOptions,
            accessToken: accessToken,
            expiresIn: expiresIn,
            tokenType: tokenType,
            refreshToken: refreshToken
        )
    }
}
