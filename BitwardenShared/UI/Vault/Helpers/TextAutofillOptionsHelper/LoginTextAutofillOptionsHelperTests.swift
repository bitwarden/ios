import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - LoginTextAutofillOptionsHelperTests

class LoginTextAutofillOptionsHelperTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var subject: LoginTextAutofillOptionsHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = LoginTextAutofillOptionsHelper(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available.
    func test_getTextAutofillOptions() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.password), password
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when cipher doesn't have a login.
    func test_getTextAutofillOptions_emptyNotLogin() async {
        let cipher = CipherView.fixture(
            login: nil,
            type: .login,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except username.
    func test_getTextAutofillOptions_usernameNil() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: nil,
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.password), password
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except username being empty.
    func test_getTextAutofillOptions_usernameEmpty() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: "",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.password), password
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from password.
    func test_getTextAutofillOptions_passwordNil() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: nil,
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from password being empty.
    func test_getTextAutofillOptions_passwordEmpty() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "",
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from password being empty.
    func test_getTextAutofillOptions_cannotViewPassword() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: false
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success("1234")
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.verificationCode), 1234
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except from totp because not being allowed to be copied.
    func test_getTextAutofillOptions_totpNotAllowed() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .success(nil)
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.password), password
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except from totp because
    /// checking if it's allowed throws.
    func test_getTextAutofillOptions_totpAllowedThrows() async {
        let cipher = CipherView.fixture(
            login: .fixture(
                password: "password",
                username: "username",
                totp: "1234"
            ),
            type: .login,
            viewPassword: true
        )
        vaultRepository.getTOTPKeyIfAllowedToCopyResult = .failure(BitwardenTestError.example)
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.username), username
            \(Localizations.password), password
            """
        }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
