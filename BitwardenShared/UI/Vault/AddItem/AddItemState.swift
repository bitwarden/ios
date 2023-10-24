// MARK: - AddItemState

/// An object that defines the current state of an `AddItemView`.
///
struct AddItemState {
    // MARK: Properties

    /// The folder this item should be added to.
    var folder: String = ""

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool = false

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool = false

    /// A flag indicating if the password field is visible.
    var isPasswordVisible: Bool = false

    /// The name of this item.
    var name: String = ""

    /// The password for this item.
    var password: String = ""

    /// The notes for this item.
    var notes: String = ""

    /// The owner of this item.
    var owner: String = ""

    /// What cipher type this item is.
    var type: String = "" // TODO: BIT-902 update to use CipherType

    /// The uri associated with this item. Used with autofill.
    var uri: String = "" // TODO: BIT-901 Update to use an array of CipherLoginUriModel

    /// The username for this item.
    var username: String = ""
}
