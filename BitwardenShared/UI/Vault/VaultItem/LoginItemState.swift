import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for adding a login item.
struct LoginItemState: Equatable {
    // MARK: Properties

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// The password for this item.
    var password: String = ""

    /// The date the password was last updated.
    var passwordUpdatedDate: Date?

    /// The uri associated with this item. Used with autofill.
    var uris: [CipherLoginUriModel] = [
        .init(match: nil, uri: ""),
    ] // TODO: BIT-901 Update match CipherLoginUriModel.

    /// The username for this item.
    var username: String = ""
}
