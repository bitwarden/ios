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
}
