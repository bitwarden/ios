import BitwardenSdk
import Foundation

// MARK: - CipherItemState

/// An object that defines the current state of any view interacting with a cipher item.
///
struct CipherItemState: Equatable {
    // MARK: Types

    /// An enum difining if the state is a new or existing cipher.
    enum Configuration: Equatable {
        /// A case for new ciphers.
        case add
        /// A case to view or edit an existing cipher.
        case existing(cipherView: CipherView)
    }

    /// An enumeration of the possible values of this state.
    enum ItemTypeState: Equatable {
        /// A login item's representative state.
        case login(ViewLoginItemState)
    }

    // MARK: Properties

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The custome fields.
    var customFields: [CustomFieldState]

    /// The folder this item should be added to.
    var folder: String

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The state for a login type item.
    var loginState: LoginItemState

    /// The name of this item.
    var name: String

    /// The notes for this item.
    var notes: String

    /// The owner of this item.
    var owner: String

    /// What cipher type this item is.
    var type: CipherType

    /// When this item was last updated.
    var updatedDate: Date

    // MARK: DerivedProperties

    /// The view state of the item.
    var viewState: ItemTypeState? {
        guard case let .existing(cipherView) = configuration else {
            return nil
        }
        switch type {
        case .login:
            let viewLoginState = ViewLoginItemState(
                cipher: cipherView,
                customFields: customFields,
                isMasterPasswordRePromptOn: isMasterPasswordRePromptOn,
                loginState: loginState,
                name: name,
                notes: notes,
                updatedDate: updatedDate
            )
            return .login(viewLoginState)
        case .secureNote:
            return nil
        case .card:
            return nil
        case .identity:
            return nil
        }
    }

    // MARK: Initialization

    private init(
        configuration: Configuration,
        customFields: [CustomFieldState],
        folder: String,
        isFavoriteOn: Bool,
        isMasterPasswordRePromptOn: Bool,
        loginState: LoginItemState,
        name: String,
        notes: String,
        owner: String,
        type: CipherType,
        updatedDate: Date
    ) {
        self.customFields = customFields
        self.folder = folder
        self.isFavoriteOn = isFavoriteOn
        self.isMasterPasswordRePromptOn = isMasterPasswordRePromptOn
        self.loginState = loginState
        self.name = name
        self.notes = notes
        self.owner = owner
        self.type = type
        self.updatedDate = updatedDate
        self.configuration = configuration
    }

    init(addItem type: CipherType = .login) {
        self.init(
            configuration: .add,
            customFields: [],
            folder: "",
            isFavoriteOn: false,
            isMasterPasswordRePromptOn: false,
            loginState: .init(),
            name: "",
            notes: "",
            owner: "",
            type: type,
            updatedDate: .now
        )
    }

    init?(existing cipherView: CipherView) {
        guard cipherView.id != nil else { return nil }
        self.init(
            configuration: .existing(cipherView: cipherView),
            customFields: cipherView.customFields,
            folder: cipherView.folderId ?? "",
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            loginState: cipherView.loginItemState(),
            name: cipherView.name,
            notes: cipherView.notes ?? "",
            owner: "",
            type: .init(type: cipherView.type),
            updatedDate: cipherView.revisionDate
        )
    }

    // MARK: Methods

    /// Toggles the password visibility for the specified custom field.
    ///
    /// - Parameter customFieldState: The custom field to update.
    ///
    mutating func togglePasswordVisibility(for customFieldState: CustomFieldState) {
        if let index = customFields.firstIndex(of: customFieldState) {
            customFields[index].isPasswordVisible.toggle()
        }
    }
}

extension CipherItemState {
    /// Returns a `CipherView` based on the properties of the `CipherItemState`.
    func newCipherView(creationDate: Date = .now) -> CipherView {
        var cipherView = CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: nil,
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

        switch type {
        case .login:
            cipherView.login =  BitwardenSdk.LoginView(
                username: loginState.username.nilIfEmpty,
                password: loginState.password.nilIfEmpty,
                passwordRevisionDate: nil,
                uris: nil,
                totp: nil,
                autofillOnPageLoad: nil
            )
        case .secureNote:
            cipherView.secureNote = BitwardenSdk.SecureNoteView(type: .generic)
        default:
            break
        }
        return cipherView
    }
}
