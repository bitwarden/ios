import BitwardenSdk
import Foundation

// MARK: - AddEditLoginItemState

/// The state for adding a login item.
struct AddEditLoginItemState: Equatable {
    // MARK: Properties

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// The password for this item.
    var password: String = ""

    /// The uri associated with this item. Used with autofill.
    var uris: [CipherLoginUriModel] = [] // TODO: BIT-901 Update match CipherLoginUriModel.

    /// The username for this item.
    var username: String = ""
}
