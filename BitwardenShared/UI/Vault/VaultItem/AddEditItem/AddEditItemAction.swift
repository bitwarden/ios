// MARK: - AddEditItemAction

import BitwardenKit
import BitwardenSdk
import Foundation
import SwiftUI

/// Actions that can be handled by an `AddEditItemProcessor`.
enum AddEditItemAction: Equatable, Sendable {
    /// Navigate to the add folder view.
    case addFolder

    /// The auth key visibility was toggled.
    case authKeyVisibilityTapped(Bool)

    /// A card field changed
    case cardFieldChanged(AddEditCardItemAction)

    /// Clears the URL.
    case clearUrl

    /// The toggle for including the item in a collection was changed.
    case collectionToggleChanged(Bool, collectionId: String)

    /// A custom field action was sent.
    case customField(AddEditCustomFieldsAction)

    /// The dismiss button was pressed.
    case dismissPressed

    /// The favorite toggle was changed.
    case favoriteChanged(Bool)

    /// The folder field was changed.
    case folderChanged(DefaultableType<FolderView>)

    /// The generate password button was pressed.
    case generatePasswordPressed

    /// The generate username button was pressed.
    case generateUsernamePressed

    /// A forwarded action from the guided tour view.
    case guidedTourViewAction(GuidedTourViewAction)

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

    /// The ssh key item action.
    case sshKeyItemAction(ViewSSHKeyItemAction)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// The additional options expanded section was toggled.
    case toggleAdditionalOptionsExpanded(Bool)

    /// The toggle password visibility button was changed.
    case togglePasswordVisibilityChanged(Bool)

    /// The TOTP field left focus.
    ///
    case totpFieldLeftFocus

    /// The TOTP field was changed.
    ///
    /// - Parameter newValue: the updated TOTP key.
    ///
    case totpKeyChanged(_ newValue: String?)

    /// The uri field was changed.
    case uriChanged(String, index: Int)

    /// The uri field's match type was changed.
    case uriTypeChanged(DefaultableType<UriMatchType>, index: Int)

    /// The remove uri button was pressed.
    case removeUriPressed(index: Int)

    /// The remove passkey button was pressed.
    case removePasskeyPressed

    /// The username field was changed.
    case usernameChanged(String)
}
