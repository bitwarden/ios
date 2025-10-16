import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - TextAutofillOptionsHelperFactoryTests

class TextAutofillOptionsHelperFactoryTests: BitwardenTestCase {
    // MARK: Properties

    var errorReporter: MockErrorReporter!
    var subject: TextAutofillOptionsHelperFactory!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = DefaultTextAutofillOptionsHelperFactory(
            errorReporter: errorReporter,
            vaultRepository: vaultRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        errorReporter = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `create(cipherView:)` creates a `CardTextAutofillOptionsHelper` when
    /// cipher type is secure note.
    func test_create_returnsCardOptionsHelper() {
        let optionsHelper = subject.create(cipherView: .fixture(type: .card))
        XCTAssertTrue(optionsHelper is CardTextAutofillOptionsHelper)
    }

    /// `create(cipherView:)` creates a `IdentityTextAutofillOptionsHelper` when
    /// cipher type is identity.
    func test_create_returnsIdentityOptionsHelper() {
        let optionsHelper = subject.create(cipherView: .fixture(type: .identity))
        XCTAssertTrue(optionsHelper is IdentityTextAutofillOptionsHelper)
    }

    /// `create(cipherView:)` creates a `LoginTextAutofillOptionsHelper` when
    /// cipher type is login.
    func test_create_returnsLoginOptionsHelper() {
        let optionsHelper = subject.create(cipherView: .fixture(type: .login))
        XCTAssertTrue(optionsHelper is LoginTextAutofillOptionsHelper)
    }

    /// `create(cipherView:)` creates a `SecureNoteTextAutofillOptionsHelper` when
    /// cipher type is secure note.
    func test_create_returnsSecureNoteOptionsHelper() {
        let optionsHelper = subject.create(cipherView: .fixture(type: .secureNote))
        XCTAssertTrue(optionsHelper is SecureNoteTextAutofillOptionsHelper)
    }

    /// `create(cipherView:)` creates a `SSHKeyTextAutofillOptionsHelper` when
    /// cipher type is SSH key.
    func test_create_returnsSSHKeyOptionsHelper() {
        let optionsHelper = subject.create(cipherView: .fixture(type: .sshKey))
        XCTAssertTrue(optionsHelper is SSHKeyTextAutofillOptionsHelper)
    }
}
