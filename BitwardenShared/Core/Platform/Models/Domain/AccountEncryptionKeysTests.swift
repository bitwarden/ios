import XCTest

@testable import BitwardenShared

class AccountEncryptionKeysTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(identityTokenResponseModel:)` initializes an `AccountEncryptionKeys` from an identity
    /// token response.
    func test_init_identityTokenResponseModel() {
        let subject = AccountEncryptionKeys(identityTokenResponseModel: .fixture())

        XCTAssertEqual(
            subject,
            AccountEncryptionKeys(
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
