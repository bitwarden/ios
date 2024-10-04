import BitwardenSdk
import Foundation

/// A `Sendable` type to describe the state of a Cipher for `AddEditItemView`.
///
protocol AddEditItemState: Sendable {
    // MARK: Properties

    /// Whether the user should be able to select the type of item to add.
    var allowTypeSelection: Bool { get }

    /// The card item state.
    var cardItemState: CardItemState { get set }

    /// The Cipher underpinning the state
    var cipher: CipherView { get }

    /// The list of collection IDs that the cipher is included in.
    var collectionIds: [String] { get set }

    /// The full list of collections for the user, across all organizations.
    var collections: [CollectionView] { get set }

    /// The list of collections that can be selected from for the current owner.
    var collectionsForOwner: [CollectionView] { get }

    /// The Add or Existing Configuration.
    var configuration: CipherItemState.Configuration { get }

    /// The custom fields state.
    var customFieldsState: AddEditCustomFieldsState { get set }

    /// The folder this item should be added to.
    var folder: DefaultableType<FolderView> { get set }

    /// The identifier of the folder for this item.
    var folderId: String? { get set }

    /// The list of all folders that the item could be added to.
    var folders: [DefaultableType<FolderView>] { get set }

    /// The state for a identity type item.
    var identityState: IdentityItemState { get set }

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool { get set }

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool { get set }

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool { get set }

    /// The state for a login type item.
    var loginState: LoginItemState { get set }

    /// The name of this item.
    var name: String { get set }

    /// The notes for this item.
    var notes: String { get set }

    /// The organization ID of the cipher, if the cipher is owned by an organization.
    var organizationId: String? { get }

    /// The owner of this item.
    var owner: CipherOwner? { get set }

    /// The list of ownership options to allow the user to select from.
    var ownershipOptions: [CipherOwner] { get set }

    /// If master password reprompt toggle should be shown.
    var showMasterPasswordReprompt: Bool { get set }

    /// The SSH key item state.
    var sshKeyState: SSHKeyItemState { get set }

    /// A toast message to show in the view.
    var toast: Toast? { get set }

    /// What cipher type this item is.
    var type: CipherType { get set }

    /// When this item was last updated.
    var updatedDate: Date { get set }

    /// Toggles whether the cipher is included in the specified collection.
    ///
    /// - Parameters:
    ///   - newValue: Whether the cipher is included in the collection.
    ///   - collectionId: The identifier of the collection.
    ///
    mutating func toggleCollection(newValue: Bool, collectionId: String)
}
