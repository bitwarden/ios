import BitwardenSdk
import Foundation

// MARK: - ViewLoginItemState

/// The state for viewing a login item.
struct ViewLoginItemState: Equatable {
    // MARK: Properties

    /// The custom fields in this item.
    var customFields: [FieldView] = []

    /// The folder this object resides in.
    var folder: String?

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// The name of this item.
    var name: String

    /// The notes in this item.
    var notes: String?

    /// The password for this item.
    var password: String?

    /// A formatted date for this item.
    var updatedDate: Date

    /// A list of uris associated with this item.
    var uris: [LoginUriView] = []

    /// The username for this item.
    var username: String?
}
