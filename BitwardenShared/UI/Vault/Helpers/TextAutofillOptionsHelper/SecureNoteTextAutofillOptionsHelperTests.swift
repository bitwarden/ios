import BitwardenResources
import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - SecureNoteTextAutofillOptionsHelperTests

class SecureNoteTextAutofillOptionsHelperTests: BitwardenTestCase {
    // MARK: Properties

    var subject: SecureNoteTextAutofillOptionsHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = SecureNoteTextAutofillOptionsHelper()
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
            notes: "Notes",
            secureNote: SecureNoteView(type: .generic),
            type: .secureNote
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        let dump = TextAutofillOptionsHelperDumper.dump(options)
        assertInlineSnapshot(of: dump, as: .lines) {
            """
            \(Localizations.notes), Notes
            """
        }
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when cipher doesn't have a secure note.
    func test_getTextAutofillOptions_emptyNotIdentity() async {
        let cipher = CipherView.fixture(
            secureNote: nil,
            type: .secureNote
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when notes `nil`.
    func test_getTextAutofillOptions_notesNil() async {
        let cipher = CipherView.fixture(
            notes: nil,
            secureNote: SecureNoteView(type: .generic),
            type: .secureNote
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }

    /// `getTextAutofillOptions(cipherView:)` returns empty when notes empty.
    func test_getTextAutofillOptions_notesEmpty() async {
        let cipher = CipherView.fixture(
            notes: "",
            secureNote: SecureNoteView(type: .generic),
            type: .secureNote
        )
        let options = subject.getTextAutofillOptions(cipherView: cipher)
        XCTAssertTrue(options.isEmpty)
    }
}
