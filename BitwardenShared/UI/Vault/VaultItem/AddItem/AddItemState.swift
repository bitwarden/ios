import BitwardenSdk
import Foundation

// MARK: - AddItemState

/// An object that defines the current state of an `AddItemView`.
///
struct AddItemState {
    // MARK: Properties

    /// The sub state for add login item.
    var addLoginItemState = AddLoginItemState()

    /// The folder this item should be added to.
    var folder: String = ""

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool = false

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool = false

    /// The name of this item.
    var name: String = ""

    /// The notes for this item.
    var notes: String = ""

    /// The owner of this item.
    var owner: String = ""

    /// What cipher type this item is.
    var type: CipherType = .login
}

extension AddItemState {
    /// Returns a `CipherView` based on the fields the user entered in the `AddItemView`.
    func cipher(creationDate: Date = .now) -> CipherView {
        CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: BitwardenSdk.LoginView(
                username: addLoginItemState.username.nilIfEmpty,
                password: addLoginItemState.password.nilIfEmpty,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            favorite: isFavoriteOn,
            reprompt: isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: false,
            edit: true,
            viewPassword: true,
            localData: nil,
            attachments: nil,
            fields: nil,
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate
        )
    }
}
