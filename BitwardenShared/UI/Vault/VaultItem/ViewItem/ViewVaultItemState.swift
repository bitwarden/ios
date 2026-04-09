import BitwardenSdk
import Foundation

// MARK: - ViewVaultItemState

/// The state for viewing a login item.
protocol ViewVaultItemState: Sendable, VaultItemWithDecorativeIcon {
    // MARK: Properties

    /// The item's attachments.
    var attachments: [AttachmentView]? { get }

    /// Whether the item belongs to multiple collections.
    var belongsToMultipleCollections: Bool { get }

    /// The card item state.
    var cardItemViewState: any ViewCardItemState { get }

    /// The Cipher underpinning the state
    var cipher: CipherView { get }

    /// The collections the cipher belongs to to display.
    /// When there are collections, this depends on whether the user selects
    /// show more/less for this to have one or more collections the cipher
    /// belongs to.
    var cipherCollectionsToDisplay: [CollectionView] { get }

    /// The custom fields state.
    var customFieldsState: AddEditCustomFieldsState { get set }

    /// The name of the folder the cipher belongs to, if any.
    var folderName: String? { get }

    /// The base url used to fetch icons.
    var iconBaseURL: URL? { get set }

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool { get }

    /// Whether it's showing multiple collections or not.
    var isShowingMultipleCollections: Bool { get set }

    /// A flag indicating if item was soft deleted.
    var isSoftDeleted: Bool { get }

    /// The login item state.
    var loginState: LoginItemState { get set }

    /// The identity item state.
    var identityState: IdentityItemState { get set }

    /// The title to display for the button to toggle displaying multiple collections.
    var multipleCollectionsDisplayButtonTitle: String { get }

    /// The name of this item.
    var name: String { get set }

    /// The notes of this item.
    var notes: String { get set }

    /// The name of the organization the item belongs to, if any.
    var organizationName: String? { get set }

    /// Whether the item should be displayed as archived.
    var shouldDisplayAsArchived: Bool { get }

    /// Whether to display "No Folder" to indicate the item doesn't
    /// belong to any folder, collection nor organization.
    var shouldDisplayNoFolder: Bool { get }

    /// Whether to display the folder the item belongs to.
    var shouldDisplayFolder: Bool { get }

    /// Whether to show the special web icons.
    var showWebIcons: Bool { get set }

    /// The SSH key item state.
    var sshKeyState: SSHKeyItemState { get set }

    /// The total number of header additional items: organization + collections + folder; if available.
    /// This is used for accessibility.
    var totalHeaderAdditionalItems: Int { get }

    /// When this item was last updated.
    var updatedDate: Date { get set }

    /// What cipher type this item is.
    var type: CipherType { get }
}
