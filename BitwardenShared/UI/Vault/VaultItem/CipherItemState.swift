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

    /// A flag indicating if this account has premium features.
    var accountHasPremium: Bool

    /// Whether the user should be able to select the type of item to add.
    var allowTypeSelection: Bool

    /// The card item state.
    var cardItemState: CardItemState

    /// The list of collection IDs that the cipher is included in.
    var collectionIds: [String]

    /// The full list of collections for the user, across all organizations.
    var collections: [CollectionView]

    /// The Add or Existing Configuration.
    let configuration: Configuration

    /// The custom fields.
    var customFields: [CustomFieldState]

    /// The identifier of the folder for this item.
    var folderId: String?

    /// The list of all folders that the item could be added to.
    var folders: [DefaultableType<FolderView>]

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

    /// The folder this item should be added to.
    var folder: DefaultableType<FolderView> {
        get {
            guard let folderId,
                  let folder = folders.first(where: { $0.customValue?.id == folderId })?.customValue else {
                return .default
            }
            return .custom(folder)
        } set {
            folderId = newValue.customValue?.id
        }
    }

    /// The owner of the cipher.
    var owner: CipherOwner? {
        get {
            guard let organizationId else { return ownershipOptions.first(where: \.isPersonal) }
            return ownershipOptions.first(where: { $0.organizationId == organizationId })
        }
        set {
            organizationId = newValue?.organizationId
            collectionIds = []
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
        accountHasPremium: Bool,
        allowTypeSelection: Bool,
        cardState: CardItemState,
        configuration: Configuration,
        customFields: [CustomFieldState],
        folderId: String?,
        identityState: IdentityItemState,
        isFavoriteOn: Bool,
        isMasterPasswordRePromptOn: Bool,
        loginState: LoginItemState,
        name: String,
        notes: String,
        type: CipherType,
        updatedDate: Date
    ) {
        self.accountHasPremium = accountHasPremium
        self.allowTypeSelection = allowTypeSelection
        cardItemState = cardState
        collectionIds = []
        collections = []
        self.customFields = customFields
        self.folderId = folderId
        self.identityState = identityState
        self.isFavoriteOn = isFavoriteOn
        self.isMasterPasswordRePromptOn = isMasterPasswordRePromptOn
        folders = []
        self.loginState = loginState
        self.name = name
        self.notes = notes
        ownershipOptions = []
        self.type = type
        self.updatedDate = updatedDate
        self.configuration = configuration
    }

    init(
        addItem type: CipherType = .login,
        allowTypeSelection: Bool = true,
        hasPremium: Bool,
        uri: String? = nil
    ) {
        self.init(
            accountHasPremium: hasPremium,
            allowTypeSelection: allowTypeSelection,
            cardState: .init(),
            configuration: .add,
            customFields: [],
            folderId: nil,
            identityState: .init(),
            isFavoriteOn: false,
            isMasterPasswordRePromptOn: false,
            loginState: .init(
                isTOTPAvailable: hasPremium,
                uris: [UriState(uri: uri ?? "")]
            ),
            name: uri.flatMap(URL.init)?.host ?? "",
            notes: "",
            type: type,
            updatedDate: .now
        )
    }

    init?(existing cipherView: CipherView, hasPremium: Bool, totpTime: TOTPTime) {
        guard cipherView.id != nil else { return nil }
        self.init(
            accountHasPremium: hasPremium,
            allowTypeSelection: false,
            cardState: cipherView.cardItemState(),
            configuration: .existing(cipherView: cipherView),
            customFields: cipherView.customFields,
            folderId: cipherView.folderId,
            identityState: cipherView.identityItemState(),
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            loginState: cipherView.loginItemState(showTOTP: hasPremium, totpTime: totpTime),
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
    var cardItemViewState: any ViewCardItemState {
        cardItemState
    }

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
            folderId: folderId,
            collectionIds: collectionIds,
            key: nil,
            name: name,
            notes: notes.nilIfEmpty,
            type: BitwardenSdk.CipherType(type),
            login: type == .login ? loginState.loginView : nil,
            identity: type == .identity ? identityState.identityView : nil,
            card: type == .card ? cardItemState.cardView : nil,
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
