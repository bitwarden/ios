import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class LoginViewUpdateTests: BitwardenTestCase {
    // MARK: Propteries

    var loginState: LoginItemState!
    var subject: BitwardenSdk.LoginView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = LoginView.fixture()
        loginState = LoginItemState()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// Tests that the init succeeds with no LoginView.
    func test_update_nilLoginView() {
        let comparison = BitwardenSdk.LoginView(
            loginView: nil,
            loginState: loginState
        )
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView() {
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            loginState: loginState
        )
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView_changes() {
        loginState.username = "Username"
        loginState.password = "Password"
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            loginState: loginState
        )
        XCTAssertEqual(comparison.username, loginState.username)
        XCTAssertEqual(comparison.password, loginState.password)
        XCTAssertEqual(comparison.passwordRevisionDate, subject.passwordRevisionDate)
        XCTAssertEqual(comparison.uris, subject.uris)
        XCTAssertEqual(comparison.totp, subject.totp)
        XCTAssertEqual(comparison.autofillOnPageLoad, subject.autofillOnPageLoad)
    }
}
