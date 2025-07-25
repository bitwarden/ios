import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - CardTextAutofillOptionsHelperTests

class CardTextAutofillOptionsHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CardTextAutofillOptionsHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = CardTextAutofillOptionsHelper()
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
            card: .fixture(
                cardholderName: "Cardholder",
                code: "123",
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            \(Localizations.number), 1234 5678 1234 5678
            \(Localizations.securityCode), 123
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when cipher doesn't have a card.
    func test_getTextAutofillOptions_emptyNotCard() async {
        let cipher = CipherView.fixture(
            card: nil,
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except name when
    /// cardholder name is nil.
    func test_getTextAutofillOptions_cardholderNameNil() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: nil,
                code: "123",
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.number), 1234 5678 1234 5678
            \(Localizations.securityCode), 123
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except name when
    /// cardholder name is empty.
    func test_getTextAutofillOptions_cardholderNameEmpty() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "",
                code: "123",
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.number), 1234 5678 1234 5678
            \(Localizations.securityCode), 123
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except number when
    /// number is nil.
    func test_getTextAutofillOptions_numberNil() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "Cardholder",
                code: "123",
                number: nil
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            \(Localizations.securityCode), 123
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except number when
    /// number is empty.
    func test_getTextAutofillOptions_numberEmpty() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "Cardholder",
                code: "123",
                number: ""
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            \(Localizations.securityCode), 123
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except code when
    /// code is nil.
    func test_getTextAutofillOptions_codeNil() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "Cardholder",
                code: nil,
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            \(Localizations.number), 1234 5678 1234 5678
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns all options except code when
    /// code is empty.
    func test_getTextAutofillOptions_codeEmpty() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "Cardholder",
                code: "",
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: true
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            \(Localizations.number), 1234 5678 1234 5678
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` return cardholder name only when
    /// cannot view password.
    func test_getTextAutofillOptions_cannotViewPassword() async {
        let cipher = CipherView.fixture(
            card: .fixture(
                cardholderName: "Cardholder",
                code: "123",
                number: "1234 5678 1234 5678"
            ),
            type: .card,
            viewPassword: false
        )
        let options = await subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.cardholderName), Cardholder
            """
        }
    }
}
