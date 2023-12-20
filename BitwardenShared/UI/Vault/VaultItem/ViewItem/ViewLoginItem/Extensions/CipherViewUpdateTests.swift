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

    /// Tests that the update succeeds with new properties.
    func test_update_card_edits_succeeds() {
        cipherItemState.type = .card
        let expectedCardState = CardItemState(
            brand: .custom(.visa),
            cardholderName: "Jane Doe",
            cardNumber: "12345",
            cardSecurityCode: "123",
            expirationMonth: .custom(.apr),
            expirationYear: "1234"
        )
        cipherItemState.cardItemState = expectedCardState

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.secureNote)

        XCTAssertEqual(comparison.cardItemState(), expectedCardState)

        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, cipherItemState.name)

        XCTAssertNil(comparison.notes)
        XCTAssertEqual(comparison.identity, subject.identity)
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

    /// Tests that the update succeeds with udpated properties.
    func test_update_identity_succeeds() {
        cipherItemState.type = .identity
        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .identity)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.secureNote)
        XCTAssertNotNil(comparison.identity)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_login_noEdits_succeeds() {
        let editState = CipherItemState(existing: subject)!
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(subject, comparison)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_login_edits_succeeds() {
        cipherItemState.type = .login
        cipherItemState.notes = "I have a note"
        cipherItemState.loginState.username = "PASTA"
        cipherItemState.loginState.password = "BATMAN"
        cipherItemState.isFavoriteOn = true
        cipherItemState.isMasterPasswordRePromptOn = true

        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .login)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.identity)
        XCTAssertNil(comparison.secureNote)

        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, cipherItemState.name)
        XCTAssertEqual(comparison.login?.username, cipherItemState.loginState.username)
        XCTAssertEqual(comparison.login?.password, cipherItemState.loginState.password)
        XCTAssertEqual(comparison.notes, cipherItemState.notes)
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

    /// Tests that the update succeeds with udpated properties.
    func test_update_secureNote_succeeds() {
        cipherItemState.type = .secureNote
        let comparison = subject.updatedView(with: cipherItemState)
        XCTAssertEqual(comparison.type, .secureNote)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.identity)
    }
}
