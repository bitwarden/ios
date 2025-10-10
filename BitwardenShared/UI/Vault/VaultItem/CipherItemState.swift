import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation

// MARK: - CipherItemState

/// An object that defines the current state of any view interacting with a cipher item.
///
struct CipherItemState: Equatable { // swiftlint:disable:this type_body_length
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

    /// The card item state.
    var cardItemState = CardItemState()

    /// The list of collection IDs that the cipher is included in.
    var collectionIds: [String]

    /// The full list of collections for the user, across all organizations.
    var allUserCollections = [CollectionView]()

    /// The Add or Existing Configuration.
    var configuration: Configuration

    /// The custom fields state.
    var customFieldsState: AddEditCustomFieldsState

    /// The identifier of the folder for this item.
    var folderId: String?

    /// The folder name this item belongs to, if any.
    var folderName: String?

    /// The list of all folders that the item could be added to.
    var folders = [DefaultableType<FolderView>]()

    /// The state for guided tour view.
    var guidedTourViewState = GuidedTourViewState(
        guidedTourStepStates: [
            .loginStep1,
            .loginStep2,
            .loginStep3,
        ],
    )

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The state for a identity type item.
    var identityState = IdentityItemState()

    /// Whether the additional options section is expanded.
    var isAdditionalOptionsExpanded = false

    /// A flag indicating if this item is favorited.
    var isFavoriteOn = false

    /// If account is eligible for  Learn New Login Action Card.
    var isLearnNewLoginActionCardEligible: Bool = false

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn = false

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled = false

    /// Whether it's showing multiple collections or not.
    var isShowingMultipleCollections: Bool = false

    /// The state for a login type item.
    var loginState: LoginItemState

    /// The name of this item.
    var name: String

    /// The notes for this item.
    var notes = ""

    /// The organization ID of the cipher, if the cipher is owned by an organization.
    var organizationId: String?

    /// The name of the organization the cipher belongs to, if any.
    var organizationName: String?

    /// The organization IDs that have `.personalOwnership` policy applied.
    var organizationsWithPersonalOwnershipPolicy: [String] = []

    /// The list of ownership options that can be selected for the cipher.
    var ownershipOptions = [CipherOwner]()

    /// If master password reprompt toggle should be shown
    var showMasterPasswordReprompt = true

    /// Whether the web icons should be shown.
    var showWebIcons: Bool

    /// The SSH key item state.
    var sshKeyState = SSHKeyItemState()

    /// A toast for the AddEditItemView
    var toast: Toast?

    /// What cipher type this item is.
    var type: CipherType

    /// The url to open in the device's web browser.
    var url: URL?

    /// When this item was last updated.
    var updatedDate = Date.now

    // MARK: DerivedProperties

    /// The edit state of the item.
    var addEditState: AddEditItemState {
        self
    }

    var hasOrganizations: Bool {
        cipher.organizationId != nil || ownershipOptions.contains { !$0.isPersonal }
    }

    /// Whether or not this item can be assigned to collections.
    var canAssignToCollection: Bool {
        guard hasOrganizations, cipher.organizationId != nil else { return false }
        guard !collectionIds.isEmpty else { return true }

        return allUserCollections.contains { collection in
            guard let id = collection.id else { return false }
            guard collection.manage || (!collection.readOnly && !collection.hidePasswords) else { return false }

            return collectionIds.contains(id)
        }
    }

    /// Whether or not this item can be deleted by the user.
    var canBeDeleted: Bool {
        // backwards compatibility for old server versions
        guard let cipherPermissions = cipher.permissions else {
            guard !collectionIds.isEmpty else { return true }
            return allUserCollections.contains { collection in
                guard let id = collection.id else { return false }
                return collection.manage && collectionIds.contains(id)
            }
        }

        // New permission model from PM-18091
        return cipherPermissions.delete
    }

    /// Whether or not this item can be restored by the user.
    var canBeRestored: Bool {
        // backwards compatibility for old server versions
        guard let cipherPermissions = cipher.permissions else {
            return isSoftDeleted
        }

        // New permission model from PM-18091
        return cipherPermissions.restore && isSoftDeleted
    }

    /// Whether or not this item can be moved to an organization.
    var canMoveToOrganization: Bool {
        hasOrganizations && cipher.organizationId == nil
    }

    /// The collections that the cipher belongs to.
    var cipherCollections: [CollectionView] {
        guard !collectionIds.isEmpty else {
            return []
        }
        return allUserCollections.filter { collection in
            guard let id = collection.id else {
                return false
            }
            return collectionIds.contains(id)
        }
    }

    /// The collections the cipher belongs to to display.
    /// When there are collections, this depends on whether the user selects
    /// show more/less for this to have one or more collections the cipher
    /// belongs to.
    var cipherCollectionsToDisplay: [CollectionView] {
        guard !cipherCollections.isEmpty else {
            return []
        }

        guard isShowingMultipleCollections else {
            return [cipherCollections[0]]
        }
        return cipherCollections
    }

    /// The list of collections that can be selected from for the current owner.
    /// These are collections that the user can add items to, so they are non-read-only collections.
    var collectionsForOwner: [CollectionView] {
        guard let owner, !owner.isPersonal else { return [] }
        return allUserCollections.filter { $0.organizationId == owner.organizationId && !$0.readOnly }
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

    /// Whether the cipher is read-only.
    var isReadOnly: Bool {
        cipher.edit == false
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
            selectDefaultCollectionIfNeeded()
        }
    }

    /// The flag indicating if we should show the learn new login action card.
    var shouldShowLearnNewLoginActionCard: Bool {
        isLearnNewLoginActionCardEligible && configuration == .add && type == .login
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
        collectionIds: [String] = [],
        configuration: Configuration,
        customFields: [CustomFieldState] = [],
        folderId: String? = nil,
        iconBaseURL: URL?,
        loginState: LoginItemState = .init(isTOTPAvailable: false, totpState: .init(keyModel: nil)),
        name: String = "",
        organizationId: String? = nil,
        showWebIcons: Bool,
        type: CipherType,
    ) {
        self.accountHasPremium = accountHasPremium
        self.collectionIds = collectionIds
        customFieldsState = AddEditCustomFieldsState(cipherType: type, customFields: customFields)
        self.folderId = folderId
        self.iconBaseURL = iconBaseURL
        self.loginState = loginState
        self.name = name
        self.organizationId = organizationId
        self.showWebIcons = showWebIcons
        self.type = type
        self.configuration = configuration
    }

    init(
        addItem type: CipherType = .login,
        collectionIds: [String] = [],
        customFields: [CustomFieldState] = [],
        folderId: String? = nil,
        hasPremium: Bool,
        name: String? = nil,
        organizationId: String? = nil,
        password: String? = nil,
        totpKeyString: String? = nil,
        uri: String? = nil,
        username: String? = nil,
    ) {
        self.init(
            accountHasPremium: hasPremium,
            collectionIds: collectionIds,
            configuration: .add,
            customFields: customFields,
            folderId: folderId,
            iconBaseURL: nil,
            loginState: .init(
                isTOTPAvailable: hasPremium,
                password: password ?? "",
                totpState: .init(totpKeyString),
                uris: [UriState(uri: uri ?? "")],
                username: username ?? "",
            ),
            name: name ?? uri.flatMap(URL.init)?.host ?? "",
            organizationId: organizationId,
            showWebIcons: false,
            type: type,
        )
    }

    init(cloneItem cipherView: CipherView, hasPremium: Bool) {
        self.init(
            accountHasPremium: hasPremium,
            configuration: .add,
            iconBaseURL: nil,
            showWebIcons: false,
            type: .init(type: cipherView.type),
        )
        apply(
            cipherView: cipherView,
            overrideName: "\(cipherView.name) - \(Localizations.clone)",
            overrideLoginItemState: cipherView.loginItemState(excludeFido2Credentials: true, showTOTP: hasPremium),
        )
    }

    init?(
        existing cipherView: CipherView,
        hasPremium: Bool,
        iconBaseURL: URL? = nil,
        showWebIcons: Bool = true,
    ) {
        guard cipherView.id != nil else { return nil }
        self.init(
            accountHasPremium: hasPremium,
            configuration: .existing(cipherView: cipherView),
            iconBaseURL: iconBaseURL,
            showWebIcons: showWebIcons,
            type: .init(type: cipherView.type),
        )
        apply(cipherView: cipherView)
    }

    // MARK: Methods

    /// Toggles the password visibility for the specified custom field.
    ///
    /// - Parameter customFieldState: The custom field to update.
    ///
    mutating func togglePasswordVisibility(for customFieldState: CustomFieldState) {
        if let index = customFieldsState.customFields.firstIndex(of: customFieldState) {
            customFieldsState.customFields[index].isPasswordVisible.toggle()
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

    /// Applies values from the given `CipherView` to the cipher driven properties in the state.
    ///
    /// - Parameters:
    ///   - cipherView: The `CipherView` whose values should be copied to the state.
    ///   - overrideName: An optional value to override the `CipherView`s name in the state. This is
    ///     primarily used when cloning a cipher to provide a default name for the cloned `CipherView`
    ///     that is different from the original.
    ///   - overrideLoginItemState: An optional value to override the `CipherView`s `LoginItemState`.
    ///     This is primarily used when cloning a cipher to exclude FIDO2 credentials.
    ///
    private mutating func apply(
        cipherView: CipherView,
        overrideName: String? = nil,
        overrideLoginItemState: LoginItemState? = nil,
    ) {
        let type = CipherType(type: cipherView.type)

        if case .existing = configuration {
            configuration = .existing(cipherView: cipherView)
        }

        cardItemState = cipherView.cardItemState()
        collectionIds = cipherView.collectionIds
        customFieldsState = AddEditCustomFieldsState(cipherType: type, customFields: cipherView.customFields)
        folderId = cipherView.folderId
        identityState = cipherView.identityItemState()
        isFavoriteOn = cipherView.favorite
        isMasterPasswordRePromptOn = cipherView.reprompt == .password
        loginState = overrideLoginItemState
            ?? cipherView.loginItemState(showTOTP: accountHasPremium || cipherView.organizationUseTotp)
        name = overrideName ?? cipherView.name
        notes = cipherView.notes ?? ""
        organizationId = cipherView.organizationId
        sshKeyState = cipherView.sshKeyItemState()
        self.type = type
        updatedDate = cipherView.revisionDate
    }
}

extension CipherItemState: AddEditItemState {
    // MARK: Properties

    var navigationTitle: String {
        switch configuration {
        case .add:
            switch type {
            case .card: Localizations.newCard
            case .identity: Localizations.newIdentity
            case .login: Localizations.newLogin
            case .secureNote: Localizations.newNote
            case .sshKey: Localizations.newSSHKey
            }
        case .existing:
            switch type {
            case .card: Localizations.editCard
            case .identity: Localizations.editIdentity
            case .login: Localizations.editLogin
            case .secureNote: Localizations.editNote
            case .sshKey: Localizations.editSSHKey
            }
        }
    }

    // MARK: Methods

    mutating func selectDefaultCollectionIfNeeded() {
        guard configuration.isAdding else {
            return
        }

        let defaultCollectionForOwner = collectionsForOwner.first(where: { $0.type == .defaultUserCollection })

        guard let defaultCollectionId = defaultCollectionForOwner?.id,
              collectionIds.isEmpty,
              let ownerOrganizationId = owner?.organizationId,
              organizationsWithPersonalOwnershipPolicy.contains(ownerOrganizationId) else {
            return
        }

        collectionIds.append(defaultCollectionId)
    }

    mutating func update(from cipherView: CipherView) {
        apply(cipherView: cipherView)
    }
}

extension CipherItemState: ViewVaultItemState {
    var attachments: [AttachmentView]? {
        cipher.attachments
    }

    var belongsToMultipleCollections: Bool {
        cipher.collectionIds.count > 1
    }

    var cardItemViewState: any ViewCardItemState {
        cardItemState
    }

    var cipher: BitwardenSdk.CipherView {
        switch configuration {
        case let .existing(cipherView: view):
            view
        case .add:
            newCipherView()
        }
    }

    var cipherDecorativeIconDataView: CipherDecorativeIconDataView? {
        loginView
    }

    var icon: SharedImageAsset {
        switch cipher.type {
        case .card:
            guard case let .custom(brand) = cardItemState.brand else {
                return SharedAsset.Icons.card24
            }
            return brand.icon
        case .identity:
            return SharedAsset.Icons.idCard24
        case .login:
            return SharedAsset.Icons.globe24
        case .secureNote:
            return SharedAsset.Icons.stickyNote24
        case .sshKey:
            return SharedAsset.Icons.key24
        }
    }

    var iconAccessibilityId: String {
        "CipherIcon"
    }

    var isSoftDeleted: Bool {
        cipher.deletedDate != nil
    }

    var loginView: BitwardenSdk.LoginView? {
        cipher.login
    }

    var multipleCollectionsDisplayButtonTitle: String {
        guard !cipherCollectionsToDisplay.isEmpty else {
            return ""
        }
        if isShowingMultipleCollections {
            return Localizations.showLess
        }
        return Localizations.showMore
    }

    var shouldDisplayFolder: Bool {
        !folderName.isEmptyOrNil
            && (!belongsToMultipleCollections || isShowingMultipleCollections)
    }

    var shouldDisplayNoFolder: Bool {
        organizationId == nil
            && folderId == nil
            && collectionIds.isEmpty
    }

    var shouldUseCustomPlaceholderContent: Bool {
        guard cipher.type == .card,
              case let .custom(brand) = cardItemState.brand,
              brand != .other else {
            return true
        }
        return false
    }

    var totalHeaderAdditionalItems: Int {
        // Accessibility only uses this when there's an organization.
        guard organizationId != nil else {
            return 0
        }
        var total = 1
        total += cipher.collectionIds.count
        if !cipher.folderId.isEmptyOrNil {
            total += 1
        }
        return total
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
            sshKey: type == .sshKey ? sshKeyState.sshKeyView : nil,
            favorite: isFavoriteOn,
            reprompt: isMasterPasswordRePromptOn ? .password : .none,
            organizationUseTotp: false,
            edit: true,
            permissions: nil,
            viewPassword: true,
            localData: nil,
            attachments: nil,
            fields: customFieldsState.customFields.isEmpty ? nil : customFieldsState.customFields.map { customField in
                FieldView(
                    name: customField.name,
                    value: customField.value,
                    type: .init(fieldType: customField.type),
                    linkedId: customField.linkedIdType?.rawValue,
                )
            },
            passwordHistory: nil,
            creationDate: creationDate,
            deletedDate: nil,
            revisionDate: creationDate,
            archivedDate: nil,
        )
    }
} // swiftlint:disable:this file_length
