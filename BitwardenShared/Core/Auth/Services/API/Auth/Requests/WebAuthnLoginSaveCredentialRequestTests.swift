import BitwardenSharedMocks
import XCTest

@testable import BitwardenShared

class WebAuthnLoginSaveCredentialRequestTests: BitwardenTestCase {
    // MARK: Properties

    var subject: WebAuthnLoginSaveCredentialRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = WebAuthnLoginSaveCredentialRequest(
            requestModel: WebAuthnLoginSaveCredentialRequestModel(
                deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse.fixture(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedPublicKey: "PUBLIC_KEY",
                encryptedUserKey: "USER_KEY",
                name: "name",
                supportsPrf: true,
                token: "token",
            ),
        )
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `body` is the request model.
    func test_body() throws {
        let expected = WebAuthnLoginSaveCredentialRequestModel(
            deviceResponse: WebAuthnPublicKeyCredentialWithAttestationResponse.fixture(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedPublicKey: "PUBLIC_KEY",
            encryptedUserKey: "USER_KEY",
            name: "name",
            supportsPrf: true,
            token: "token",
        )
        XCTAssertEqual(subject.body, expected)
    }

    /// `method` is `.post`.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` is the correct value.
    func test_path() {
        XCTAssertEqual(subject.path, "/webauthn")
    }
}
