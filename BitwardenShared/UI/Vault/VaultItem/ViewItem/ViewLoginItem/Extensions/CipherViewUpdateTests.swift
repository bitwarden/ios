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
        cipherItemState = .init(hasPremium: true)
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
        cipherItemState.identityState = .fixture(
            title: .custom(.mx),
            firstName: "Spontaneous",
            lastName: "Combust",
            middleName: "Lee",
            userName: "sbl-wow",
            company: "ACME",
            socialSecurityNumber: "555-55-5555",
            passportNumber: "55555555",
            licenseNumber: "DL5555555",
            email: "sbl-combust@acme.org",
            phone: "1-555-555-5555",
            address1: "555 Coyote Ln",
            address2: "Apt 2",
            address3: "",
            cityOrTown: "Sedona",
            state: "AZ",
            postalCode: "55555",
            country: "US"
        )

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
    }

    /// Tests that the update succeeds with matching properties.
    func test_update_identity_succeeds() throws {
        var editState = try XCTUnwrap(
            CipherItemState(
                existing: subject,
                hasPremium: true,
                totpTime: .currentTime
            )
        )
        editState.type = .identity
        editState.identityState = .fixture(
            title: .custom(.mx),
            firstName: "Spontaneous",
            lastName: "Combust",
            middleName: "Lee",
            userName: "sbl-wow",
            company: "ACME",
            socialSecurityNumber: "555-55-5555",
            passportNumber: "55555555",
            licenseNumber: "DL5555555",
            email: "sbl-combust@acme.org",
            phone: "1-555-555-5555",
            address1: "555 Coyote Ln",
            address2: "Apt 2",
            address3: "",
            cityOrTown: "Sedona",
            state: "AZ",
            postalCode: "55555",
            country: "US"
        )
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(
            comparison.identity,
            .init(
                identityView: subject.identity,
                identityState: editState.identityState
            )
        )
        XCTAssertEqual(comparison.type, .identity)
        XCTAssertNil(comparison.card)
        XCTAssertNil(comparison.login)
        XCTAssertNil(comparison.secureNote)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_noEdits_succeeds() {
        let editState = CipherItemState(
            existing: subject,
            hasPremium: true,
            totpTime: .currentTime
        )!
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(subject, comparison)
    }

    /// Tests that the update succeeds with new properties.
    func test_update_login_noEdits_succeeds() throws {
        let editState = try XCTUnwrap(
            CipherItemState(
                existing: subject,
                hasPremium: true,
                totpTime: .currentTime
            )
        )
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

    /// Tests that the update succeeds with new properties.
    func test_update_identity_edits_nilValues() throws {
        let state = CipherItemState(
            existing: subject,
            hasPremium: true,
            totpTime: .currentTime
        )
        var editState = try XCTUnwrap(state)
        editState.type = .identity
        editState.identityState = .fixture(
            title: .default
        )
        let comparison = subject.updatedView(with: editState)
        XCTAssertEqual(
            comparison.identity,
            .init(
                identityView: subject.identity,
                identityState: editState.identityState
            )
        )

        XCTAssertEqual(comparison.type, .identity)
        let identity = try XCTUnwrap(comparison.identity)
        XCTAssertNil(identity.title)
        XCTAssertNil(identity.firstName)
        XCTAssertNil(identity.lastName)
        XCTAssertNil(identity.middleName)
        XCTAssertNil(identity.username)
        XCTAssertNil(identity.company)
        XCTAssertNil(identity.ssn)
        XCTAssertNil(identity.passportNumber)
        XCTAssertNil(identity.licenseNumber)
        XCTAssertNil(identity.email)
        XCTAssertNil(identity.phone)
        XCTAssertNil(identity.address1)
        XCTAssertNil(identity.address2)
        XCTAssertNil(identity.address3)
        XCTAssertNil(identity.city)
        XCTAssertNil(identity.state)
        XCTAssertNil(identity.postalCode)
        XCTAssertNil(identity.country)
    }
}
