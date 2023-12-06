import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class CipherViewUpdateTests: BitwardenTestCase {
    // MARK: Propteries

    var properties: CipherItemProperties!
    var subject: BitwardenSdk.CipherView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        subject = CipherView.loginFixture()
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

    /// Tests that the update succeeds with matching properties.
    func test_update_identity_succeeds() {
        let comparison = subject.updatedView(with: .editItem(cipherView: subject)!)
        XCTAssertEqual(comparison, subject)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_noEdits_succeeds() {
        var editState = AddEditItemState.editItem(cipherView: subject)!
        editState.properties = properties

        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, properties.name)
        XCTAssertEqual(comparison.notes, nil)
        XCTAssertEqual(comparison.login?.username, nil)
        XCTAssertEqual(comparison.login?.password, nil)
        XCTAssertEqual(comparison.type, .login)
        XCTAssertEqual(comparison.identity, subject.identity)
        XCTAssertEqual(comparison.card, subject.card)
        XCTAssertEqual(comparison.secureNote, subject.secureNote)
        XCTAssertEqual(comparison.favorite, properties.isFavoriteOn)
        XCTAssertEqual(
            comparison.reprompt,
            properties.isMasterPasswordRePromptOn ? .password : .none
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

    /// Tests that the update succeeds with new properties.
    func test_update_edits_succeeds() {
        var editState = AddEditItemState.editItem(cipherView: subject)!
        properties.notes = "I have a note"
        properties.username = "PASTA"
        properties.password = "BATMAN"
        properties.isFavoriteOn = true
        properties.isMasterPasswordRePromptOn = true
        editState.properties = properties

        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(comparison.id, subject.id)
        XCTAssertEqual(comparison.organizationId, subject.organizationId)
        XCTAssertEqual(comparison.folderId, subject.folderId)
        XCTAssertEqual(comparison.collectionIds, subject.collectionIds)
        XCTAssertEqual(comparison.name, properties.name)
        XCTAssertEqual(comparison.login?.username, properties.username)
        XCTAssertEqual(comparison.login?.password, properties.password)
        XCTAssertEqual(comparison.notes, properties.notes)
        XCTAssertEqual(comparison.type, .login)
        XCTAssertEqual(comparison.identity, subject.identity)
        XCTAssertEqual(comparison.card, subject.card)
        XCTAssertEqual(comparison.secureNote, subject.secureNote)
        XCTAssertEqual(comparison.favorite, properties.isFavoriteOn)
        XCTAssertEqual(
            comparison.reprompt,
            properties.isMasterPasswordRePromptOn ? .password : .none
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
