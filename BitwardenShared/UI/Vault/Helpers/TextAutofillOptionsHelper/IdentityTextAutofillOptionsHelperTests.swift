import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - IdentityTextAutofillOptionsHelperTests

class IdentityTextAutofillOptionsHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var subject: IdentityTextAutofillOptionsHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = IdentityTextAutofillOptionsHelper()
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available.
    func test_getTextAutofillOptions() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when cipher doesn't have an identity.
    func test_getTextAutofillOptions_emptyNotIdentity() async {
        let cipher = CipherView.fixture(
            identity: nil,
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from first name.
    func test_getTextAutofillOptions_firstNameNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: nil,
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from first name being empty.
    func test_getTextAutofillOptions_firstNameEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from last name.
    func test_getTextAutofillOptions_lastNameNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: nil,
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns options when
    /// we have all of the values available except from last name being empty.
    func test_getTextAutofillOptions_lastNameEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except from SSN.
    func test_getTextAutofillOptions_SSNNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: nil,
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except SSN being empty.
    func test_getTextAutofillOptions_SSNEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except passport number.
    func test_getTextAutofillOptions_passportNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: nil
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except passport number being empty.
    func test_getTextAutofillOptions_passportEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: ""
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.email), email@example.com
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except from email.
    func test_getTextAutofillOptions_emailNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: nil,
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available except from email being empty.
    func test_getTextAutofillOptions_emailEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "",
                phone: "123456789",
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.phone), 123456789
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available exept from phone.
    func test_getTextAutofillOptions_phoneNil() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: nil,
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options when
    /// we have all of the values available exept from phone being empty.
    func test_getTextAutofillOptions_phoneEmpty() async {
        let cipher = CipherView.fixture(
            identity: .fixture(
                firstName: "First",
                lastName: "Last",
                email: "email@example.com",
                phone: nil,
                ssn: "SSN",
                passportNumber: "Passport"
            ),
            type: .identity
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.fullName), First Last
            \(Localizations.ssn), SSN
            \(Localizations.passportNumber), Passport
            \(Localizations.email), email@example.com
            """
        }
    }
}
