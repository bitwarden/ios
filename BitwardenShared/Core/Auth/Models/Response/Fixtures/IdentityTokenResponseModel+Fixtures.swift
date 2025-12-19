@testable import BitwardenShared

extension AuthMethodsData {
    static func fixture() -> AuthMethodsData {
        let methodsData = AuthMethodsData(
            authenticator: true,
            email: Email(email: "sh***@example.com"),
            yubikey: Yubikey(nfc: true),
        )
        return methodsData
    }

    static func fixtureWebAuthn() -> AuthMethodsData {
        let methodsData = AuthMethodsData(
            email: Email(email: "sh***@example.com"),
            yubikey: Yubikey(nfc: true),
            webAuthn: WebAuthn(
                allowCredentials: [
                    AllowCredential(
                        id: "_YSahxwU5GEkoLbFOBSMgRVoCwUZMAhuC_HhLnwG123",
                        type: "public-key",
                    ),
                ],
                challenge: "3Hu2GPMuYlbKqRQgdlu123",
                errorMessage: "",
                rpId: "vault.bitwarden.com",
                status: "ok",
                timeout: 60000,
                userVerification: "discouraged",
            ),
        )
        return methodsData
    }
}

extension IdentityTokenResponseModel {
    static func fixture(
        accountKeys: PrivateKeysResponseModel? = nil,
        forcePasswordReset: Bool = false,
        kdf: KdfType = .pbkdf2sha256,
        kdfIterations: Int = 600_000,
        kdfMemory: Int? = nil,
        kdfParallelism: Int? = nil,
        key: String? = "KEY",
        keyConnectorUrl: String? = nil,
        masterPasswordPolicy: MasterPasswordPolicyResponseModel? = nil,
        privateKey: String? = "PRIVATE_KEY",
        twoFactorToken: String? = nil,
        userDecryptionOptions: UserDecryptionOptions? = UserDecryptionOptions(
            hasMasterPassword: true,
            keyConnectorOption: nil,
            trustedDeviceOption: nil,
        ),
        // swiftlint:disable:next line_length
        accessToken: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTY5MDg4NzksInN1YiI6IjEzNTEyNDY3LTljZmUtNDNiMC05NjlmLTA3NTM0MDg0NzY0YiIsIm5hbWUiOiJCaXR3YXJkZW4gVXNlciIsImVtYWlsIjoidXNlckBiaXR3YXJkZW4uY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlhdCI6MTUxNjIzOTAyMiwicHJlbWl1bSI6ZmFsc2UsImFtciI6WyJBcHBsaWNhdGlvbiJdfQ.KDqC8kUaOAgBiUY8eeLa0a4xYWN8GmheXTFXmataFwM",
        expiresIn: Int = 3600,
        tokenType: String = "Bearer",
        refreshToken: String = "REFRESH_TOKEN",
    ) -> IdentityTokenResponseModel {
        IdentityTokenResponseModel(
            accountKeys: accountKeys,
            forcePasswordReset: forcePasswordReset,
            kdf: kdf,
            kdfIterations: kdfIterations,
            kdfMemory: kdfMemory,
            kdfParallelism: kdfParallelism,
            key: key,
            keyConnectorUrl: keyConnectorUrl,
            masterPasswordPolicy: masterPasswordPolicy,
            privateKey: privateKey,
            twoFactorToken: twoFactorToken,
            userDecryptionOptions: userDecryptionOptions,
            accessToken: accessToken,
            expiresIn: expiresIn,
            tokenType: tokenType,
            refreshToken: refreshToken,
        )
    }
}
