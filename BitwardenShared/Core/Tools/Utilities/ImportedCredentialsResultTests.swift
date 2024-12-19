import XCTest

@testable import BitwardenShared

// MARK: - ImportedCredentialsResultTests

class ImportedCredentialsResultTests: BitwardenTestCase {
    // MARK: Properties

    var subject: ImportedCredentialsResult!

    // MARK: Setup & Teardown

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `localizedTypePlural` returns the localized string for the type in plural.
    func test_localizedTypePlural() {
        subject = ImportedCredentialsResult(count: 1, type: .card)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.cards)

        subject = ImportedCredentialsResult(count: 1, type: .identity)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.identities)

        subject = ImportedCredentialsResult(count: 1, type: .passkey)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.passkeys)

        subject = ImportedCredentialsResult(count: 1, type: .password)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.passwords)

        subject = ImportedCredentialsResult(count: 1, type: .secureNote)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.secureNotes)

        subject = ImportedCredentialsResult(count: 1, type: .sshKey)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.sshKeys)
    }
}
