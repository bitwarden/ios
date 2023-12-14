import BitwardenSdk
import Foundation

// MARK: - CipherItemState

/// An object that defines the current state of any view interacting with a cipher item.
///
struct CipherItemState: Equatable {
    // MARK: Types

    /// An enum defining if the state is a new or existing cipher.
    enum Configuration: Equatable {
        /// A case for new ciphers.
        case add
        /// A case to view or edit an existing cipher.
        case existing(cipherView: CipherView)

        /// The existing `CipherView` if the configuration is `existing`.
        var existingCipherView: CipherView? {
            guard case let .existing(cipherView) = self else { return nil }
            return cipherView
        }
    }

    // MARK: Properties

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The custom fields.
    var customFields: [CustomFieldState]

    /// The folder this item should be added to.
    var folder: String

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The state for a login type item.
    var loginState: LoginItemState

    /// The state for a identity type item.
    var identityState: IdentityItemState

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
    var viewState: ViewVaultItemState? {
        guard let cipherView = configuration.existingCipherView else {
            return nil
        }
        return ViewVaultItemState(
            cipher: cipherView,
            customFields: customFields,
            isMasterPasswordRePromptOn: isMasterPasswordRePromptOn,
            loginState: loginState,
            name: name,
            notes: notes,
            updatedDate: updatedDate
        )
    }

    // MARK: Initialization

    private init(
        configuration: Configuration,
        customFields: [CustomFieldState],
        folder: String,
        identityState: IdentityItemState,
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
        self.identityState = identityState
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
            identityState: .init(),
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
            identityState: cipherView.identityItemState(),
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
        CipherView(
            id: nil,
            organizationId: nil,
            folderId: nil,
            collectionIds: [],
            key: nil,
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: type == .login ? loginState.loginView : nil,
            identity: nil,
            card: nil,
            secureNote: type == .secureNote ? .init(type: .generic) : nil,
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
