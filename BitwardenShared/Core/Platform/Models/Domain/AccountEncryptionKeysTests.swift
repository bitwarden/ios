import BitwardenSdk
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AccountEncryptionKeysTests

struct AccountEncryptionKeysTests {
    // MARK: Tests

    /// `init(responseModel:)` initializes an `AccountEncryptionKeys` from a response model with encryption keys.
    @Test
    func init_responseModel() {
        let accountKeys = PrivateKeysResponseModel.fixtureFilled()
        let subject = AccountEncryptionKeys(
            responseModel: ProfileResponseModel.fixture(
                accountKeys: accountKeys,
                key: "KEY",
                privateKey: "PRIVATE_KEY",
            ),
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: accountKeys,
                encryptedPrivateKey: "WRAPPED_PRIVATE_KEY",
                encryptedUserKey: "KEY",
            ),
        )
    }

    /// `init(responseModel:)` initializes an `AccountEncryptionKeys` from a response model with encryption keys
    /// but no account keys.
    @Test
    func init_responseModel_noAccountKeys() {
        let subject = AccountEncryptionKeys(
            responseModel: IdentityTokenResponseModel.fixture(
                accountKeys: nil,
                key: "KEY",
                privateKey: "PRIVATE_KEY",
            ),
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "KEY",
            ),
        )
    }

    /// `init(responseModel:)` returns `nil` if the response model doesn't contain encryption keys.
    @Test
    func init_responseModel_missingKeys() {
        let subject = AccountEncryptionKeys(
            responseModel: IdentityTokenResponseModel.fixture(accountKeys: nil, key: nil, privateKey: nil),
        )
        #expect(subject == nil)
    }

    /// `init(accountCryptographicState:)` initializes from a V1 state with only a private key.
    @Test
    func init_accountCryptographicState_v1() {
        let subject = AccountEncryptionKeys(
            accountCryptographicState: .v1(privateKey: "PRIVATE_KEY"),
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: nil,
            ),
        )
    }

    /// `init(accountCryptographicState:encryptedUserKey:)` initializes from a V1 state with an encrypted user key.
    @Test
    func init_accountCryptographicState_v1_withEncryptedUserKey() {
        let subject = AccountEncryptionKeys(
            accountCryptographicState: .v1(privateKey: "PRIVATE_KEY"),
            encryptedUserKey: "USER_KEY",
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        )
    }

    /// `init(accountCryptographicState:)` initializes from a V2 state with all fields present.
    @Test
    func init_accountCryptographicState_v2() {
        let subject = AccountEncryptionKeys(
            accountCryptographicState: .v2(
                privateKey: "PRIVATE_KEY",
                signedPublicKey: "SIGNED_PUBLIC_KEY",
                signingKey: "SIGNING_KEY",
                securityState: "SECURITY_STATE",
            ),
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: PrivateKeysResponseModel(
                    publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel(
                        publicKey: "",
                        signedPublicKey: "SIGNED_PUBLIC_KEY",
                        wrappedPrivateKey: "PRIVATE_KEY",
                    ),
                    signatureKeyPair: SignatureKeyPairResponseModel(
                        wrappedSigningKey: "SIGNING_KEY",
                        verifyingKey: "",
                    ),
                    securityState: SecurityStateResponseModel(securityState: "SECURITY_STATE"),
                ),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: nil,
            ),
        )
    }

    /// `init(accountCryptographicState:)` initializes from a V2 state with a nil signed public key.
    @Test
    func init_accountCryptographicState_v2_nilSignedPublicKey() {
        let subject = AccountEncryptionKeys(
            accountCryptographicState: .v2(
                privateKey: "PRIVATE_KEY",
                signedPublicKey: nil,
                signingKey: "SIGNING_KEY",
                securityState: "SECURITY_STATE",
            ),
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: PrivateKeysResponseModel(
                    publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel(
                        publicKey: "",
                        signedPublicKey: nil,
                        wrappedPrivateKey: "PRIVATE_KEY",
                    ),
                    signatureKeyPair: SignatureKeyPairResponseModel(
                        wrappedSigningKey: "SIGNING_KEY",
                        verifyingKey: "",
                    ),
                    securityState: SecurityStateResponseModel(securityState: "SECURITY_STATE"),
                ),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: nil,
            ),
        )
    }

    /// `init(accountCryptographicState:encryptedUserKey:)` initializes from a V2 state with an encrypted user key.
    @Test
    func init_accountCryptographicState_v2_withEncryptedUserKey() {
        let subject = AccountEncryptionKeys(
            accountCryptographicState: .v2(
                privateKey: "PRIVATE_KEY",
                signedPublicKey: "SIGNED_PUBLIC_KEY",
                signingKey: "SIGNING_KEY",
                securityState: "SECURITY_STATE",
            ),
            encryptedUserKey: "USER_KEY",
        )

        #expect(
            subject == AccountEncryptionKeys(
                accountKeys: PrivateKeysResponseModel(
                    publicKeyEncryptionKeyPair: PublicKeyEncryptionKeyPairResponseModel(
                        publicKey: "",
                        signedPublicKey: "SIGNED_PUBLIC_KEY",
                        wrappedPrivateKey: "PRIVATE_KEY",
                    ),
                    signatureKeyPair: SignatureKeyPairResponseModel(
                        wrappedSigningKey: "SIGNING_KEY",
                        verifyingKey: "",
                    ),
                    securityState: SecurityStateResponseModel(securityState: "SECURITY_STATE"),
                ),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        )
    }
}
