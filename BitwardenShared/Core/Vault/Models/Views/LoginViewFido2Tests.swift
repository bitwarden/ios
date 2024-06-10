import BitwardenSdk
import XCTest

@testable import BitwardenShared

class LoginViewFido2Tests: BitwardenTestCase {
    // MARK: Tests

    /// `hasFido2Credentials` with Fido2 credentials nil.
    func test_hasFido2Credentials_nilFido2Credentials() {
        let subject = LoginView.fixture()
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with empty Fido2 credentials.
    func test_hasFido2Credentials_emptyFido2Credentials() {
        let subject = LoginView.fixture(fido2Credentials: [])
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with Fido2 credentials.
    func test_hasFido2Credentials_withFido2Credentials() {
        let subject = LoginView.fixture(fido2Credentials: [Fido2CredentialView.fixture()])
        XCTAssertTrue(subject.hasFido2Credentials)
    }

    /// `mainFido2Credential` with no Fido2 credentials
    func test_mainFido2Credential_noFido2Credentials() {
        let subject = LoginView.fixture()
        XCTAssertNil(subject.mainFido2Credential)
    }

    /// `mainFido2Credential` with no Fido2 credentials
    func test_mainFido2Credential_withFido2Credentials() {
        let subject = LoginView.fixture(fido2Credentials: [Fido2CredentialView.fixture()])
        XCTAssertNotNil(subject.mainFido2Credential)
    }
}
