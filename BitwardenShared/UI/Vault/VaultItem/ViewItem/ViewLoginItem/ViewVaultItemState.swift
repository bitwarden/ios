import BitwardenSdk
import Foundation

// MARK: - ViewLoginItemState

/// The state for viewing a login item.
struct ViewVaultItemState: Equatable {
    // MARK: Properties

    /// The Cipher underpinning the state
    var cipher: CipherView

    /// The custome fields.
    var customFields: [CustomFieldState]

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The login item state.
    var loginState: LoginItemState?

    /// The name of this item.
    var name: String

    /// The notes of this item.
    var notes: String

    /// When this item was last updated.
    var updatedDate: Date

    /// What cipher type this item is.
    let type: CipherType = .login
}
