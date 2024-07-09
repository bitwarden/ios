import BitwardenSdk
import XCTest

@testable import BitwardenShared

class CipherViewFido2Tests: BitwardenTestCase {
    // MARK: Tests

    /// `hasFido2Credentials` with no login type returns that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_notLogin() {
        let subject = CipherView.fixture(type: .card)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login type but no login returns that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_noLogin() {
        let subject = CipherView.fixture(type: .login)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login that doesn't have Fido2 credentials.
    func test_hasFido2Credentials_noFido2Credentials() {
        let subject = CipherView.fixture(login: LoginView.fixture(), type: .login)
        XCTAssertFalse(subject.hasFido2Credentials)
    }

    /// `hasFido2Credentials` with login and Fido2 credentials returns `true`.
    func test_hasFido2Credentials_withFido2Credentials() {
        let subject = CipherView.fixture(
            login: LoginView.fixture(fido2Credentials: [Fido2Credential.fixture()]),
            type: .login
        )
        XCTAssertTrue(subject.hasFido2Credentials)
    }
}
