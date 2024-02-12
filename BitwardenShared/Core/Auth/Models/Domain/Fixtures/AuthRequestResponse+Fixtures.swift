import BitwardenSdk

extension AuthRequestResponse {
    static func fixture(
        privateKey: String = "PRIVATE_KEY",
        publicKey: String = "PUBLIC_KEY",
        fingerprint: String = "FINGERPRINT",
        accessCode: String = "ACCESS_CODE"
    ) -> AuthRequestResponse {
        AuthRequestResponse(
            privateKey: privateKey,
            publicKey: publicKey,
            fingerprint: fingerprint,
            accessCode: accessCode
        )
    }
}
