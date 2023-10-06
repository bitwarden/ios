import XCTest

@testable import BitwardenShared

// MARK: - CreateAccountRequestTests

class CreateAccountRequestTests: BitwardenTestCase {
    /// Validate that the method is correct.
    func test_method() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                key: "key",
                keys: KeysRequestModel(encryptedPrivateKey: "private"),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint"
            )
        )
        XCTAssertEqual(subject.method, .post)
    }

    /// Validate that the path is correct.
    func test_path() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                key: "key",
                keys: KeysRequestModel(encryptedPrivateKey: "private"),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint"
            )
        )
        XCTAssertEqual(subject.path, "/accounts/register")
    }

    /// Validate that the body is not nil.
    func test_body() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                key: "key",
                keys: KeysRequestModel(encryptedPrivateKey: "private"),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint"
            )
        )
        XCTAssertNotNil(subject.body)
    }

    // MARK: Init

    /// Validate that the value provided to the init method is correct.
    func test_init_body() {
        let subject = CreateAccountRequest(
            body: CreateAccountRequestModel(
                email: "example@email.com",
                kdfConfig: KdfConfig(),
                key: "key",
                keys: KeysRequestModel(encryptedPrivateKey: "private"),
                masterPasswordHash: "1a2b3c",
                masterPasswordHint: "hint"
            )
        )
        XCTAssertEqual(subject.body?.email, "example@email.com")
    }
}
