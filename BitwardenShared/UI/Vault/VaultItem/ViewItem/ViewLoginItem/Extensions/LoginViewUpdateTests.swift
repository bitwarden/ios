import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class LoginViewUpdateTests: BitwardenTestCase {
    // MARK: Propteries

    var properties: CipherItemProperties!
    var subject: BitwardenSdk.LoginView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = LoginView.fixture()
        properties = CipherItemProperties(
            folder: "",
            isFavoriteOn: false,
            isMasterPasswordRePromptOn: false,
            name: "",
            notes: "",
            password: "",
            type: .login,
            updatedDate: .now,
            username: ""
        )
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
            properties: properties
        )
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView() {
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            properties: properties
        )
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the init succeeds with a LoginView.
    func test_update_loginView_changes() {
        properties.username = "Username"
        properties.password = "Password"
        let comparison = BitwardenSdk.LoginView(
            loginView: subject,
            properties: properties
        )
        XCTAssertEqual(comparison.username, properties.username)
        XCTAssertEqual(comparison.password, properties.password)
        XCTAssertEqual(comparison.passwordRevisionDate, subject.passwordRevisionDate)
        XCTAssertEqual(comparison.uris, subject.uris)
        XCTAssertEqual(comparison.totp, subject.totp)
        XCTAssertEqual(comparison.autofillOnPageLoad, subject.autofillOnPageLoad)
    }
}
