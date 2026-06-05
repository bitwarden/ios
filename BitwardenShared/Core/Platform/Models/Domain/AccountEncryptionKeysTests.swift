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
                cryptographicState: .fixtureV2(),
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
                cryptographicState: .v1(privateKey: "PRIVATE_KEY"),
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
}
