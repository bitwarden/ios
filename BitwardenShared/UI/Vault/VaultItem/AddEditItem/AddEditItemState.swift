import BitwardenSdk
import Foundation

// MARK: - AddEditItemState

/// An object that defines the current state of an `AddEditItemView`.
///
struct AddEditItemState {
    enum Configuration: Equatable {
        case add
        case edit(cipherView: CipherView, savedProperties: CipherItemProperties)

        func hasChanges(edits: CipherItemProperties) -> Bool {
            switch self {
            case .add:
                return true
            case let .edit(_, savedProperties):
                return edits != savedProperties
            }
        }
    }

    // MARK: Properties

    /// The Add/Edit Configuration
    let configuration: Configuration

    /// A flag for if a user has edits
    var hasEdits: Bool {
        configuration.hasChanges(edits: properties)
    }

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// The editable properties of the Login Item
    var properties: CipherItemProperties

    static func addItem(for type: CipherType? = .login) -> Self {
        self.init(
            configuration: .add,
            properties: .init(
                folder: "",
                isFavoriteOn: false,
                isMasterPasswordRePromptOn: false,
                name: "",
                notes: "",
                password: "",
                type: type ?? .login,
                updatedDate: .now,
                uris: [
                    .init(match: nil, uri: ""),
                ],
                username: ""
            )
        )
    }

    static func editItem(cipherView: CipherView) -> Self? {
        guard let properties = CipherItemProperties.from(cipherView) else { return nil }
        return self.init(
            configuration: .edit(
                cipherView: cipherView,
                savedProperties: properties
            ),
            properties: properties
        )
    }
}

struct CipherItemProperties: Equatable {
    // MARK: Properties

    /// The custom fields in this item.
    var customFields: [CustomFieldState] = []

    /// The folder of the item.
    var folder: String

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The name of this item.
    var name: String

    /// The notes in this item.
    var notes: String

    /// The owner of this item.
    var owner: String = ""

    /// The password for this item.
    var password: String

    /// When the password for this item was last updated.
    var passwordUpdatedDate: Date?

    /// What cipher type this item is.
    var type: CipherType

    /// When this item was last updated.
    var updatedDate: Date

    /// A list of uris associated with this item.
    var uris: [CipherLoginUriModel] = [] // TODO: BIT-901 Update match CipherLoginUriModel.

    /// The username for this item.
    var username: String

    /// Creates a `CipherItemProperties` from a cipher view
    ///
    /// - Parameter cipherView: The `CipherView` containing the item properties.
    /// - Returns: An optional `CipherItemProperties` struct.
    ///     Presently only non-nil for `CipherType.login` items.
    ///
    static func from(_ cipherView: CipherView) -> CipherItemProperties? {
        guard let id = cipherView.id,
              !id.isEmpty else { return nil }
        let uris = cipherView.login?.uris?.map { uriView in
            CipherLoginUriModel(loginUriView: uriView)
        }
        return CipherItemProperties(
            customFields: cipherView.fields?.map(CustomFieldState.init) ?? [],
            folder: cipherView.folderId ?? "",
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            name: cipherView.name,
            notes: cipherView.notes ?? "",
            password: cipherView.login?.password ?? "",
            passwordUpdatedDate: cipherView.login?.passwordRevisionDate,
            type: .login,
            updatedDate: cipherView.revisionDate,
            uris: uris ?? [
                .init(match: nil, uri: nil),
            ],
            username: cipherView.login?.username ?? ""
        )
    }
}

extension AddEditItemState {
    /// Returns a `CipherView` based on the properties of the `AddEditItemState`.
    func newCipherView(creationDate: Date = .now) -> CipherView {
        CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            name: properties.name,
            notes: properties.notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(.login),
            login: BitwardenSdk.LoginView(
                username: properties.username.nilIfEmpty,
                password: properties.password.nilIfEmpty,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            ),
            identity: nil,
            card: nil,
            secureNote: nil,
            favorite: properties.isFavoriteOn,
            reprompt: properties.isMasterPasswordRePromptOn ? .password : .none,
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
