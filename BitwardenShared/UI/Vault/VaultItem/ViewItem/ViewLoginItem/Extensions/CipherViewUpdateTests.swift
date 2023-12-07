import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class CipherViewUpdateTests: BitwardenTestCase {
    // MARK: Propteries

    var cipherItemState: CipherItemState!
    var subject: BitwardenSdk.CipherView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = CipherView.loginFixture()
        cipherItemState = .init()
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
        cipherItemState = nil
    }

    // MARK: Tests

    /// Tests that the update succeeds with matching properties.
    func test_update_identity_succeeds() {
        let comparison = subject.updatedView(with: CipherItemState(existing: subject)!)
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_noEdits_succeeds() {
        let editState = CipherItemState(existing: subject)!
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(subject, comparison)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_edits_succeeds() {
        cipherItemState.notes = "I have a note"
        cipherItemState.loginState.username = "PASTA"
        cipherItemState.loginState.password = "BATMAN"
        cipherItemState.isFavoriteOn = true
        cipherItemState.isMasterPasswordRePromptOn = true

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, cipherItemState.name)
        XCTAssertEqual(comparison.login?.username, cipherItemState.loginState.username)
        XCTAssertEqual(comparison.login?.password, cipherItemState.loginState.password)
        XCTAssertEqual(comparison.notes, cipherItemState.notes)
        XCTAssertEqual(comparison.type, .login)
        XCTAssertEqual(comparison.identity, subject.identity)
        XCTAssertEqual(comparison.card, subject.card)
        XCTAssertEqual(comparison.secureNote, subject.secureNote)
        XCTAssertEqual(comparison.favorite, cipherItemState.isFavoriteOn)
        XCTAssertEqual(
            comparison.reprompt,
            cipherItemState.isMasterPasswordRePromptOn ? .password : .none
        )
        XCTAssertEqual(comparison.organizationUseTotp, false)
        XCTAssertEqual(comparison.edit, true)
        XCTAssertEqual(comparison.viewPassword, true)
        XCTAssertEqual(comparison.localData, subject.localData)
        XCTAssertEqual(comparison.attachments, subject.attachments)
        XCTAssertEqual(comparison.fields, subject.fields)
        XCTAssertEqual(comparison.passwordHistory, subject.passwordHistory)
        XCTAssertEqual(comparison.creationDate, subject.creationDate)
        XCTAssertEqual(comparison.deletedDate, nil)
        XCTAssertEqual(comparison.revisionDate, subject.revisionDate)
    }
}
