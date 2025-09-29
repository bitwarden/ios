import BitwardenResources
import XCTest

@testable import BitwardenShared

// MARK: - ViewItemStateTests

class ViewItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `canClone` is true when the cipher belongs to user but not organization.
    func test_canClone() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            )
        )
        XCTAssertTrue(subject.canClone)
    }

    /// `canClone` is false when the cipher belongs to an organization.
    func test_canClone_cipher_belongToOrg() {
        let subject = ViewItemState(
            loadingState: .data(
                CipherItemState(
                    existing: .fixture(
                        id: "id",
                        organizationId: "1234123",
                        reprompt: .password
                    ),
                    hasPremium: true
                )!
            )
        )
        XCTAssertFalse(subject.canClone)
    }

    /// `canEdit` returns `true` for a cipher that isn't deleted.
    func test_canEdit() throws {
        let subject = try ViewItemState(loadingState: .data(
            XCTUnwrap(CipherItemState(existing: .fixture(), hasPremium: false))
        ))
        XCTAssertTrue(subject.canEdit)
    }

    /// `canEdit` returns `false` for a cipher that is deleted.
    func test_canEdit_deleted() throws {
        let subject = try ViewItemState(loadingState: .data(
            XCTUnwrap(CipherItemState(existing: .fixture(deletedDate: .now), hasPremium: false))
        ))
        XCTAssertFalse(subject.canEdit)
    }

    /// `navigationTitle` returns the navigation title for the view based on the cipher type.
    func test_navigationTitle_loaded() throws {
        let subjectCard = try ViewItemState(
            loadingState: .data(XCTUnwrap(CipherItemState(existing: .fixture(type: .card), hasPremium: false)))
        )
        XCTAssertEqual(subjectCard.navigationTitle, Localizations.viewCard)

        let subjectIdentity = try ViewItemState(
            loadingState: .data(XCTUnwrap(CipherItemState(existing: .fixture(type: .identity), hasPremium: false)))
        )
        XCTAssertEqual(subjectIdentity.navigationTitle, Localizations.viewIdentity)

        let subjectLogin = try ViewItemState(
            loadingState: .data(XCTUnwrap(CipherItemState(existing: .fixture(type: .login), hasPremium: false)))
        )
        XCTAssertEqual(subjectLogin.navigationTitle, Localizations.viewLogin)

        let subjectSecureNote = try ViewItemState(
            loadingState: .data(XCTUnwrap(CipherItemState(existing: .fixture(type: .secureNote), hasPremium: false)))
        )
        XCTAssertEqual(subjectSecureNote.navigationTitle, Localizations.viewNote)

        let subjectSSHKey = try ViewItemState(
            loadingState: .data(XCTUnwrap(CipherItemState(existing: .fixture(type: .sshKey), hasPremium: false)))
        )
        XCTAssertEqual(subjectSSHKey.navigationTitle, Localizations.viewSSHKey)
    }

    /// `navigationTitle` returns an empty navigation title for the view before the item is loaded.
    func test_navigationTitle_loading() {
        let subject = ViewItemState()
        XCTAssertEqual(subject.navigationTitle, "")
    }
}
