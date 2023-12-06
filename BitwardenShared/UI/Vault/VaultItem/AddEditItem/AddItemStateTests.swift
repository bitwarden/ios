import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - AddItemStateTests

class AddItemStateTests: XCTestCase {
    // MARK: Tests

    /// `cipher` returns a `CipherView` for a login with the minimal fields entered.
    func test_cipher_login_minimal() {
        var subject = AddEditItemState.addItem()
        subject.properties.name = "Bitwarden"

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
              - localData: Optional<LocalDataView>.none
              ▿ login: Optional<LoginView>
                ▿ some: LoginView
                  - autofillOnPageLoad: Optional<Bool>.none
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
    func test_cipher_login_filled() {
        var subject = AddEditItemState.addItem()
        subject.properties.isFavoriteOn = true
        subject.properties.isMasterPasswordRePromptOn = true
        subject.properties.name = "Bitwarden"
        subject.properties.password = "top secret!"
        subject.properties.notes = "Bitwarden Login"
        subject.properties.username = "user@bitwarden.com"

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
              - localData: Optional<LocalDataView>.none
              ▿ login: Optional<LoginView>
                ▿ some: LoginView
                  - autofillOnPageLoad: Optional<Bool>.none
                  ▿ password: Optional<String>
                    - some: "top secret!"
                  - passwordRevisionDate: Optional<Date>.none
                  - totp: Optional<String>.none
                  - uris: Optional<Array<LoginUriView>>.none
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
}
