// MARK: - AddEditItemAction

import BitwardenSdk

/// Actions that can be handled by an `AddEditItemProcessor`.
enum AddEditItemAction: Equatable {
    /// A card field changed
    case cardFieldChanged(AddEditCardItemAction)

    /// The toggle for including the item in a collection was changed.
    case collectionToggleChanged(Bool, collectionId: String)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The favorite toggle was changed.
    case favoriteChanged(Bool)

    /// The folder field was changed.
    case folderChanged(String)

    /// The generate password button was pressed.
    case generatePasswordPressed

    /// The generate username button was pressed.
    case generateUsernamePressed

    /// The identity field was changed.
    case identityFieldChanged(AddEditIdentityItemAction)

    /// The master password re-prompt toggle was changed.
    case masterPasswordRePromptChanged(Bool)

    /// The more button was pressed.
    case morePressed(VaultItemManagementMenuAction)

    /// The name field was changed.
    case nameChanged(String)

    /// The new custom field button was pressed.
    case newCustomFieldPressed

    /// The new uri button was pressed.
    case newUriPressed

    /// The notes field was changed.
    case notesChanged(String)

    /// The owner field was changed.
    case ownerChanged(CipherOwner)

    /// The password field was changed.
    case passwordChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The toggle password visibility button was changed.
    case togglePasswordVisibilityChanged(Bool)

    /// The TOTP field was changed.
    ///
    /// - Parameter newValue: the updated TOTP key.
    ///
    case totpKeyChanged(_ newValue: String?)

    /// The type field was changed.
    case typeChanged(CipherType)

    /// The uri field was changed.
    case uriChanged(String, index: Int)

    /// The uri field's match type was changed.
    case uriTypeChanged(DefaultableType<UriMatchType>, index: Int)

    /// The remove uri button was pressed.
    case removeUriPressed(index: Int)

    /// The username field was changed.
    case usernameChanged(String)
}
