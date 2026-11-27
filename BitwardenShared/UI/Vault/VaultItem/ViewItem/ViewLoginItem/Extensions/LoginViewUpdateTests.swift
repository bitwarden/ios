import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class LoginViewUpdateTests: BitwardenTestCase {
    // MARK: Properties

    var loginState: LoginItemState!
    var subject: BitwardenSdk.LoginView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = LoginView.fixture()
        loginState = LoginItemState(isTOTPAvailable: true, totpState: .none)
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
            loginState: loginState,
        )
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView() {
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            loginState: loginState,
        )
        XCTAssertEqual(comparison, subject)
    }

    /// `update(password:passwordRevisionDate:)` returns a copy of the login with the new password and
    /// revision date, keeping the other properties.
    func test_update_password() {
        let date = Date(year: 2026, month: 11, day: 23)

        let updated = subject.update(password: "new", passwordRevisionDate: date)

        XCTAssertEqual(updated.password, "new")
        XCTAssertEqual(updated.passwordRevisionDate, date)
        XCTAssertEqual(updated.username, subject.username)
        XCTAssertEqual(updated.uris, subject.uris)
        XCTAssertEqual(updated.totp, subject.totp)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView_changes() {
        loginState.username = "Username"
        loginState.password = "Password"
        loginState.passwordUpdatedDate = Date()
        loginState.uris = [UriState(uri: "example.com")]
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            loginState: loginState,
        )
        XCTAssertEqual(comparison.username, loginState.username)
        XCTAssertEqual(comparison.password, loginState.password)
        XCTAssertEqual(comparison.passwordRevisionDate, loginState.passwordUpdatedDate)
        XCTAssertEqual(comparison.uris, [LoginUriView.fixture(uri: "example.com", match: nil)])
        XCTAssertEqual(comparison.totp, subject.totp)
        XCTAssertEqual(comparison.autofillOnPageLoad, subject.autofillOnPageLoad)
    }

    /// Tests that the init succeeds with a LoginView when the `loginState` doesn't have `passwordUpdateDate`.
    func test_update_loginView_changesNoPasswordUpdatedDate() {
        loginState.username = "Username"
        loginState.password = "Password"
        loginState.passwordUpdatedDate = nil
        loginState.uris = [UriState(uri: "example.com")]
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            loginState: loginState,
        )
        XCTAssertEqual(comparison.username, loginState.username)
        XCTAssertEqual(comparison.password, loginState.password)
        XCTAssertEqual(comparison.passwordRevisionDate, subject.passwordRevisionDate)
        XCTAssertEqual(comparison.uris, [LoginUriView.fixture(uri: "example.com", match: nil)])
        XCTAssertEqual(comparison.totp, subject.totp)
        XCTAssertEqual(comparison.autofillOnPageLoad, subject.autofillOnPageLoad)
    }
}
