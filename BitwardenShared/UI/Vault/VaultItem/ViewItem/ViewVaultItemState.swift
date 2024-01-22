import BitwardenSdk
import Foundation

// MARK: - ViewVaultItemState

/// The state for viewing a login item.
protocol ViewVaultItemState: Sendable {
    // MARK: Properties

    /// The item's attachments.
    var attachments: [AttachmentView]? { get }

    /// The card item state.
    var cardItemViewState: any ViewCardItemState { get }

    /// The Cipher underpinning the state
    var cipher: CipherView { get }

    /// The custom fields state.
    var customFieldsState: AddEditCustomFieldsState { get set }

    /// A flag indicating if item was soft deleted.
    var isSoftDeleted: Bool { get }

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool { get set }

    /// The login item state.
    var loginState: LoginItemState { get set }

    /// The identity item state.
    var identityState: IdentityItemState { get set }

    /// The name of this item.
    var name: String { get set }

    /// The notes of this item.
    var notes: String { get set }

    /// When this item was last updated.
    var updatedDate: Date { get set }

    /// What cipher type this item is.
    var type: CipherType { get }
}
