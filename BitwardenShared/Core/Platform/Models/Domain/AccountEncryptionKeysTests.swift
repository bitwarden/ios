import XCTest

@testable import BitwardenShared

class AccountEncryptionKeysTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(identityTokenResponseModel:)` initializes an `AccountEncryptionKeys` from an identity
    /// token response.
    func test_init_identityTokenResponseModel() {
        let accountKeys = PrivateKeysResponseModel.fixture()
        let subject = AccountEncryptionKeys(identityTokenResponseModel: .fixture(accountKeys: accountKeys))

        XCTAssertEqual(
            subject,
            AccountEncryptionKeys(
                accountKeys: accountKeys,
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "KEY"
            )
        )
    }

    /// `init(identityTokenResponseModel:)` returns `nil` if the response model doesn't contain encryption keys.
    func test_init_identityTokenResponseModel_missingKeys() {
        let subject = AccountEncryptionKeys(identityTokenResponseModel: .fixture(key: nil, privateKey: nil))
        XCTAssertNil(subject)
    }
}
