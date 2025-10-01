@testable import BitwardenShared

extension PrivateKeysResponseModel {
    static func fixture(
        publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel = .fixture(),
        signatureKeyPair: SignatureKeyPairResponseModel? = nil,
        securityState: SecurityStateResponseModel? = nil,
    ) -> PrivateKeysResponseModel {
        self.init(
            publicKeyEncryptionKeyPair: publicKeyEncryptionKeyPair,
            signatureKeyPair: signatureKeyPair,
            securityState: securityState,
        )
    }

    static func fixtureFilled() -> PrivateKeysResponseModel {
        self.init(
            publicKeyEncryptionKeyPair: .fixtureFilled(),
            signatureKeyPair: SignatureKeyPairResponseModel(
                wrappedSigningKey: "WRAPPED_SIGNING_KEY",
                verifyingKey: "VERIFYING_KEY",
            ),
            securityState: SecurityStateResponseModel(securityState: "SECURITY_STATE"),
        )
    }
}

extension PublicKeyEncryptionKeyPairResponseModel {
    static func fixture(
        publicKey: String = "",
        signedPublicKey: SignedPublicKey? = nil,
        wrappedPrivateKey: WrappedPrivateKey = "",
    ) -> PublicKeyEncryptionKeyPairResponseModel {
        self.init(
            publicKey: publicKey,
            signedPublicKey: signedPublicKey,
            wrappedPrivateKey: wrappedPrivateKey,
        )
    }

    static func fixtureFilled() -> PublicKeyEncryptionKeyPairResponseModel {
        self.init(
            publicKey: "PUBLIC_KEY",
            signedPublicKey: "SIGNED_PUBLIC_KEY",
            wrappedPrivateKey: "WRAPPED_PRIVATE_KEY",
        )
    }
}
