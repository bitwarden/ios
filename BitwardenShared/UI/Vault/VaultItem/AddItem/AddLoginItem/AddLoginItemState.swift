import BitwardenSdk
import Foundation

// MARK: - AddLoginItemState

/// The state for adding a login item.
struct AddLoginItemState: Equatable {
    // MARK: Properties

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// The password for this item.
    var password: String = ""

    /// The uri associated with this item. Used with autofill.
    var uri: String = "" // TODO: BIT-901 Update to use an array of CipherLoginUriModel

    /// The username for this item.
    var username: String = ""
}
