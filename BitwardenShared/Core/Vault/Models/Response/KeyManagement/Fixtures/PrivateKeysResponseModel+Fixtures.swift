@testable import BitwardenShared

extension PrivateKeysResponseModel {
    static func fixture(
        publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel = .fixture(),
        signatureKeyPair: SignatureKeyPairResponseModel? = nil,
        securityState: SecurityStateResponseModel? = nil
    ) -> PrivateKeysResponseModel {
        self.init(
            publicKeyEncryptionKeyPair: publicKeyEncryptionKeyPair,
            signatureKeyPair: signatureKeyPair,
            securityState: securityState
        )
    }
}

extension PublicKeyEncryptionKeyPairResponseModel {
    static func fixture(
        wrappedPrivateKey: WrappedPrivateKey = "",
        publicKey: UnsignedPublicKey = [],
        signedPublicKey: SignedPublicKey? = nil
    ) -> PublicKeyEncryptionKeyPairResponseModel {
        self.init(
            wrappedPrivateKey: wrappedPrivateKey,
            publicKey: publicKey,
            signedPublicKey: signedPublicKey
        )
    }
}
