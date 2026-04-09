import Networking
import XCTest

@testable import BitwardenShared

class WebAuthnLoginGetCredentialCreationOptionsRequestTests: BitwardenTestCase {
    // swiftlint:disable:previous type_name

    // MARK: Properties

    var subject: WebAuthnLoginGetCredentialCreationOptionsRequest!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = WebAuthnLoginGetCredentialCreationOptionsRequest(
            requestModel: SecretVerificationRequestModel(type: .masterPasswordHash("PASSWORD_HASH")),
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `body` returns the body of the request.
    func test_body() throws {
        XCTAssertEqual(
            subject.body,
            SecretVerificationRequestModel(type: .masterPasswordHash("PASSWORD_HASH")),
        )
    }

    /// `method` returns the method of the request.
    func test_method() {
        XCTAssertEqual(subject.method, .post)
    }

    /// `path` returns the path of the request.
    func test_path() {
        XCTAssertEqual(subject.path, "/webauthn/attestation-options")
    }
}
