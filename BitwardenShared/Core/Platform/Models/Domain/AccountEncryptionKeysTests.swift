import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

class AccountEncryptionKeysTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(responseModel:)` initializes an `AccountEncryptionKeys` from a response model with encryption keys.
    func test_init_responseModel() {
        let accountKeys = PrivateKeysResponseModel.fixtureFilled()
        let subject = AccountEncryptionKeys(
            responseModel: ProfileResponseModel.fixture(
                accountKeys: accountKeys,
                key: "KEY",
                privateKey: "PRIVATE_KEY",
            ),
        )

        XCTAssertEqual(
            subject,
            AccountEncryptionKeys(
                accountKeys: accountKeys,
                encryptedPrivateKey: "WRAPPED_PRIVATE_KEY",
                encryptedUserKey: "KEY",
            ),
        )
    }

    /// `init(responseModel:)` initializes an `AccountEncryptionKeys` from a response model with encryption keys
    /// but no account keys.
    func test_init_responseModelNoAccountKeys() {
        let subject = AccountEncryptionKeys(
            responseModel: IdentityTokenResponseModel.fixture(
                accountKeys: nil,
                key: "KEY",
                privateKey: "PRIVATE_KEY",
            ),
        )

        XCTAssertEqual(
            subject,
            AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "KEY",
            ),
        )
    }

    /// `init(responseModel:)` returns `nil` if the response model doesn't contain encryption keys.
    func test_init_responseModel_missingKeys() {
        let subject = AccountEncryptionKeys(
            responseModel: IdentityTokenResponseModel.fixture(accountKeys: nil, key: nil, privateKey: nil),
        )
        XCTAssertNil(subject)
    }
}
