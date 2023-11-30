import BitwardenSdk
import Foundation

// MARK: - LoginItemState

/// The state for viewing a login item.
struct LoginItemState: Equatable {
    enum EditState: Equatable {
        case view
        case edit(EditLoginItemState)

        func hasChanges(savedProperties: VaultCipherItemProperties) -> Bool {
            switch self {
            case .view:
                return false
            case let .edit(editState):
                return editState.properties != savedProperties
            }
        }
    }

    // MARK: Properties

    /// The Cipher underpinning the state
    var cipher: CipherView

    /// The edit state for the view
    var editState: EditState = .view

    /// A flag for if a user has edits
    var hasEdits: Bool {
        editState.hasChanges(savedProperties: properties)
    }

    /// A flag indicating if the password is visible.
    var isPasswordVisible = false

    /// The editable properties of the Login Item
    var properties: VaultCipherItemProperties

    // MARK: Initializers

    /// Creates a new LoginItemState
    ///
    /// - Parameter cipherView: The Cipher View the item represents.
    ///
    init?(cipherView: CipherView) {
        guard let properties = VaultCipherItemProperties.from(cipherView) else { return nil }
        cipher = cipherView
        self.properties = properties
    }

    // MARK: Methods

    /// Toggles the password visibility for the specified custom field.
    ///
    /// - Parameter customFieldState: The custom field to update.
    ///
    mutating func togglePasswordVisibility(for customFieldState: CustomFieldState) {
        if let index = properties.customFields.firstIndex(of: customFieldState) {
            properties.customFields[index].isPasswordVisible.toggle()
        }
    }
}

struct VaultCipherItemProperties: Equatable {
    // MARK: Properties

    /// The custom fields in this item.
    var customFields: [CustomFieldState] = []

    /// The folder of the item.
    var folder: String

    /// A flag indicating if this item is favorited.
    var isFavoriteOn: Bool

    /// A flag indicating if master password re-prompt is required.
    var isMasterPasswordRePromptOn: Bool

    /// The name of this item.
    var name: String

    /// The notes in this item.
    var notes: String

    /// The password for this item.
    var password: String

    /// When the password for this item was last updated.
    var passwordUpdatedDate: Date?

    /// What cipher type this item is.
    var type: CipherType

    /// When this item was last updated.
    var updatedDate: Date

    /// A list of uris associated with this item.
    var uris: [LoginUriView] = [] // TODO: BIT-901 Update match CipherLoginUriModel.

    /// The username for this item.
    var username: String

    /// Creates a `VaultCipherItemProperties` from a cipher view
    ///
    /// - Parameter cipherView: The `CipherView` containing the item properties.
    /// - Returns: An optional `VaultCipherItemProperties` struct.
    ///     Presently only non-nil for `CipherType.login` items.
    ///
    static func from(_ cipherView: CipherView) -> VaultCipherItemProperties? {
        guard let loginItem = cipherView.login else { return nil }
        return VaultCipherItemProperties(
            customFields: cipherView.fields?.map(CustomFieldState.init) ?? [],
            folder: cipherView.folderId ?? "",
            isFavoriteOn: cipherView.favorite,
            isMasterPasswordRePromptOn: cipherView.reprompt == .password,
            name: cipherView.name,
            notes: cipherView.notes ?? "",
            password: loginItem.password ?? "",
            passwordUpdatedDate: loginItem.passwordRevisionDate,
            type: .login,
            updatedDate: cipherView.revisionDate,
            uris: loginItem.uris ?? [],
            username: loginItem.username ?? ""
        )
    }
}
