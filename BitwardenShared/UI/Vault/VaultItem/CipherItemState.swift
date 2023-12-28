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

        /// Whether the configuration is for adding a new cipher.
        var isAdding: Bool {
            guard case .add = self else { return false }
            return true
        }
    }

    // MARK: Properties

    /// The list of collection IDs that the cipher is included in.
    var collectionIds: [String]

    /// The full list of collections for the user, across all organizations.
    var collections: [CollectionView]

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The custom fields.
    var customFields: [CustomFieldState]

    /// The folder this item should be added to.
    var folder: String

    /// The state for a identity type item.
    var identityState: IdentityItemState

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

    /// The organization ID of the cipher, if the cipher is owned by an organization.
    var organizationId: String?

    /// The list of ownership options that can be selected for the cipher.
    var ownershipOptions: [CipherOwner]

    /// A toast for the AddEditItemView
    var toast: Toast?

    /// What cipher type this item is.
    var type: CipherType

    /// When this item was last updated.
    var updatedDate: Date

    // MARK: DerivedProperties

    /// The edit state of the item.
    var addEditState: AddEditItemState {
        self
    }

    /// The list of collections that can be selected from for the current owner.
    var collectionsForOwner: [CollectionView] {
        guard let owner, !owner.isPersonal else { return [] }
        return collections.filter { $0.organizationId == owner.organizationId }
    }

    /// The owner of the cipher.
    var owner: CipherOwner? {
        get {
            guard let organizationId else { return ownershipOptions.first(where: \.isPersonal) }
            return ownershipOptions.first(where: { $0.organizationId == organizationId })
        }
        set {
            organizationId = newValue?.organizationId
        }
    }

    /// The view state of the item.
    var viewState: ViewVaultItemState? {
        guard case .existing = configuration else {
            return nil
        }

        return self
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
        type: CipherType,
        updatedDate: Date
    ) {
        collectionIds = []
        collections = []
        self.customFields = customFields
        self.folder = folder
        self.identityState = identityState
        self.isFavoriteOn = isFavoriteOn
        self.isMasterPasswordRePromptOn = isMasterPasswordRePromptOn
        self.loginState = loginState
        self.name = name
        self.notes = notes
        ownershipOptions = []
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

    /// Toggles whether the cipher is included in the specified collection.
    ///
    /// - Parameters:
    ///   - newValue: Whether the cipher is included in the collection.
    ///   - collectionId: The identifier of the collection.
    ///
    mutating func toggleCollection(newValue: Bool, collectionId: String) {
        if newValue {
            collectionIds.append(collectionId)
        } else {
            collectionIds = collectionIds.filter { $0 != collectionId }
        }
    }
}

extension CipherItemState: AddEditItemState {}

extension CipherItemState: ViewVaultItemState {
    var cipher: BitwardenSdk.CipherView {
        switch configuration {
        case let .existing(cipherView: view):
            return view
        case .add:
            return newCipherView()
        }
    }
}

extension CipherItemState {
    /// Returns a `CipherView` based on the properties of the `CipherItemState`.
    func newCipherView(creationDate: Date = .now) -> CipherView {
        CipherView(
            id: nil,
            organizationId: organizationId,
            folderId: nil,
            collectionIds: collectionIds,
            key: nil,
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: type == .login ? loginState.loginView : nil,
            identity: type == .identity ? identityState.identityView : nil,
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
