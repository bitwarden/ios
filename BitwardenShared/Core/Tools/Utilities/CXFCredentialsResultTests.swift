import XCTest

import BitwardenResources
@testable import BitwardenShared

// MARK: - CXFCredentialsResultTests

class CXFCredentialsResultTests: BitwardenTestCase {
    // MARK: Properties

    var subject: CXFCredentialsResult!

    // MARK: Setup & Teardown

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `localizedTypePlural` returns the localized string for the type in plural.
    func test_localizedTypePlural() {
        subject = CXFCredentialsResult(count: 1, type: .card)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.cards)

        subject = CXFCredentialsResult(count: 1, type: .identity)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.identities)

        subject = CXFCredentialsResult(count: 1, type: .passkey)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.passkeys)

        subject = CXFCredentialsResult(count: 1, type: .password)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.passwords)

        subject = CXFCredentialsResult(count: 1, type: .secureNote)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.secureNotes)

        subject = CXFCredentialsResult(count: 1, type: .sshKey)
        XCTAssertEqual(subject.localizedTypePlural, Localizations.sshKeys)
    }

    /// `getter:isEmpty` returns `true` is no credential were imported, `false` otherwise.
    func test_isEmpty() {
        subject = CXFCredentialsResult(count: 0, type: .identity)
        XCTAssertTrue(subject.isEmpty)

        subject = CXFCredentialsResult(count: 1, type: .card)
        XCTAssertFalse(subject.isEmpty)
    }
}
