import BitwardenSdk
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AddItemStateTests

class AddItemStateTests: XCTestCase {
    // MARK: Tests

    /// `cipher` returns a `CipherView` for a login with the minimal fields entered.
    func test_cipher_login_minimal() {
        var subject = CipherItemState(hasPremium: true)
        subject.name = "Bitwarden"

        assertInlineSnapshot(of: subject.newCipherView(creationDate: Date(year: 2023, month: 10, day: 20)), as: .dump) {
            """
            ▿ CipherView
              - attachments: Optional<Array<AttachmentView>>.none
              - card: Optional<CardView>.none
              - collectionIds: 0 elements
              - creationDate: 2023-10-20T00:00:00Z
              - deletedDate: Optional<Date>.none
              - edit: true
              - favorite: false
              - fields: Optional<Array<FieldView>>.none
              - folderId: Optional<String>.none
              - id: Optional<String>.none
              - identity: Optional<IdentityView>.none
              - key: Optional<String>.none
              - localData: Optional<LocalDataView>.none
              ▿ login: Optional<LoginView>
                ▿ some: LoginView
                  - autofillOnPageLoad: Optional<Bool>.none
                  ▿ fido2Credentials: Optional<Array<Fido2Credential>>
                    - some: 0 elements
                  - password: Optional<String>.none
                  - passwordRevisionDate: Optional<Date>.none
                  - totp: Optional<String>.none
                  - uris: Optional<Array<LoginUriView>>.none
                  - username: Optional<String>.none
              - name: "Bitwarden"
              - notes: Optional<String>.none
              - organizationId: Optional<String>.none
              - organizationUseTotp: false
              - passwordHistory: Optional<Array<PasswordHistoryView>>.none
              - reprompt: CipherRepromptType.none
              - revisionDate: 2023-10-20T00:00:00Z
              - secureNote: Optional<SecureNoteView>.none
              - type: CipherType.login
              - viewPassword: true

            """
        }
    }

    /// `cipher` returns a `CipherView` for a login with all fields entered.
    func test_cipher_login_filled() { // swiftlint:disable:this function_body_length
        var subject = CipherItemState(hasPremium: true)
        subject.isFavoriteOn = true
        subject.isMasterPasswordRePromptOn = true
        subject.name = "Bitwarden"
        subject.notes = "Bitwarden Login"
        subject.loginState.password = "top secret!"
        subject.loginState.uris = [.init(uri: "https://example.com")]
        subject.loginState.username = "user@bitwarden.com"

        assertInlineSnapshot(of: subject.newCipherView(creationDate: Date(year: 2023, month: 9, day: 1)), as: .dump) {
            """
            ▿ CipherView
              - attachments: Optional<Array<AttachmentView>>.none
              - card: Optional<CardView>.none
              - collectionIds: 0 elements
              - creationDate: 2023-09-01T00:00:00Z
              - deletedDate: Optional<Date>.none
              - edit: true
              - favorite: true
              - fields: Optional<Array<FieldView>>.none
              - folderId: Optional<String>.none
              - id: Optional<String>.none
              - identity: Optional<IdentityView>.none
              - key: Optional<String>.none
              - localData: Optional<LocalDataView>.none
              ▿ login: Optional<LoginView>
                ▿ some: LoginView
                  - autofillOnPageLoad: Optional<Bool>.none
                  ▿ fido2Credentials: Optional<Array<Fido2Credential>>
                    - some: 0 elements
                  ▿ password: Optional<String>
                    - some: "top secret!"
                  - passwordRevisionDate: Optional<Date>.none
                  - totp: Optional<String>.none
                  ▿ uris: Optional<Array<LoginUriView>>
                    ▿ some: 1 element
                      ▿ LoginUriView
                        - match: Optional<UriMatchType>.none
                        ▿ uri: Optional<String>
                          - some: "https://example.com"
                        - uriChecksum: Optional<String>.none
                  ▿ username: Optional<String>
                    - some: "user@bitwarden.com"
              - name: "Bitwarden"
              ▿ notes: Optional<String>
                - some: "Bitwarden Login"
              - organizationId: Optional<String>.none
              - organizationUseTotp: false
              - passwordHistory: Optional<Array<PasswordHistoryView>>.none
              - reprompt: CipherRepromptType.password
              - revisionDate: 2023-09-01T00:00:00Z
              - secureNote: Optional<SecureNoteView>.none
              - type: CipherType.login
              - viewPassword: true

            """
        }
    }

    /// `collectionsForOwner` returns the filtered collections based on the selected owner.
    func test_collectionsForOwner() {
        let collectionOrg1 = CollectionView.fixture(id: "1", name: "Collection", organizationId: "1")
        let collectionOrg2 = CollectionView.fixture(id: "2", name: "Collection 2", organizationId: "2")

        var subject = CipherItemState(hasPremium: true)
        subject.collections = [collectionOrg1, collectionOrg2]
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Organization 1"),
            .organization(id: "2", name: "Organization 2"),
        ]

        XCTAssertEqual(subject.collectionsForOwner, [])

        subject.owner = .organization(id: "1", name: "Organization")
        XCTAssertEqual(subject.collectionsForOwner, [collectionOrg1])
    }

    /// `toggleCollection(newValue:collectionId:)` toggles whether the cipher is included in the collection.
    func test_toggleCollection() {
        var subject = CipherItemState(hasPremium: true)
        subject.collections = [
            .fixture(id: "1", name: "Collection 1"),
            .fixture(id: "2", name: "Collection 2"),
        ]

        subject.toggleCollection(newValue: true, collectionId: "1")
        XCTAssertEqual(subject.collectionIds, ["1"])

        subject.toggleCollection(newValue: true, collectionId: "2")
        XCTAssertEqual(subject.collectionIds, ["1", "2"])

        subject.toggleCollection(newValue: false, collectionId: "1")
        XCTAssertEqual(subject.collectionIds, ["2"])
    }

    /// `owner` returns the selected `CipherOwner` for an organization owned cipher.
    func test_owner_organization() {
        var subject = CipherItemState(hasPremium: true)

        XCTAssertNil(subject.owner)

        subject.organizationId = "1"
        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Organization"),
        ]
        XCTAssertEqual(subject.owner, .organization(id: "1", name: "Organization"))
    }

    /// `owner` returns the selected `CipherOwner` for a personally owned cipher.
    func test_owner_personal() {
        var subject = CipherItemState(hasPremium: true)

        XCTAssertNil(subject.owner)

        subject.ownershipOptions = [
            .personal(email: "user@bitwarden.com"),
            .organization(id: "1", name: "Organization"),
        ]
        XCTAssertEqual(subject.owner, .personal(email: "user@bitwarden.com"))
    }

    /// Changing the owner clears the list of a cipher's `collectionIds`.
    func test_owner_clearsCollectionIds() {
        let personalOwner = CipherOwner.personal(email: "user@bitwarden.com")
        let organization1Owner = CipherOwner.organization(id: "1", name: "Organization")
        let organization2Owner = CipherOwner.organization(id: "2", name: "Organization 2")

        var subject = CipherItemState(hasPremium: true)
        subject.ownershipOptions = [personalOwner, organization1Owner, organization2Owner]

        subject.owner = organization1Owner

        subject.collectionIds = ["1"]
        subject.owner = organization2Owner
        XCTAssertTrue(subject.collectionIds.isEmpty)

        subject.collectionIds = ["2"]
        subject.owner = personalOwner
        XCTAssertTrue(subject.collectionIds.isEmpty)
    }

    /// Setting the owner updates the cipher's `organizationId`.`
    func test_owner_updatesOrganizationId() {
        let personalOwner = CipherOwner.personal(email: "user@bitwarden.com")
        let organization1Owner = CipherOwner.organization(id: "1", name: "Organization")
        let organization2Owner = CipherOwner.organization(id: "2", name: "Organization 2")

        var subject = CipherItemState(hasPremium: true)
        subject.ownershipOptions = [personalOwner, organization1Owner, organization2Owner]

        XCTAssertEqual(subject.owner, personalOwner)
        XCTAssertNil(subject.organizationId)

        subject.owner = organization1Owner
        XCTAssertEqual(subject.owner, organization1Owner)
        XCTAssertEqual(subject.organizationId, "1")

        subject.owner = organization2Owner
        XCTAssertEqual(subject.owner, organization2Owner)
        XCTAssertEqual(subject.organizationId, "2")
    }
}
