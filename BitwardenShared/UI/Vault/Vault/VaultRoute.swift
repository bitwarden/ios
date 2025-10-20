import BitwardenSdk
import Foundation

// MARK: - VaultRoute

/// A route to a specific screen in the vault tab.
public enum VaultRoute: Equatable, Hashable {
    /// A route to the add account flow.
    case addAccount

    /// A route to the add folder screen.
    case addFolder

    /// A route to the add item screen.
    ///
    /// - Parameters:
    ///   - group: An optional `VaultListGroup` that the user wants to add an item for.
    ///   - newCipherOptions: Options that can be used to pre-populate the add item screen.
    ///   - organizationId: The organization id in case an organization was selected in the vault filter.
    ///   - type: The type of item to add.
    ///
    case addItem(
        group: VaultListGroup? = nil,
        newCipherOptions: NewCipherOptions? = nil,
        organizationId: String? = nil,
        type: CipherType,
    )

    /// A route to the autofill list screen.
    case autofillList

    /// A route to the autofill list screen with a specified group.
    case autofillListForGroup(_ group: VaultListGroup)

    /// A route to edit an item.
    ///
    /// - Parameter cipher: The `CipherView` to edit.
    ///
    case editItem(_ cipher: CipherView)

    /// A route to edit an item based on its ID.
    ///
    /// - Parameter id: The ID of the cipher to edit.
    ///
    case editItemFrom(id: String)

    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to the flight recorder settings in the settings tab.
    case flightRecorderSettings

    /// A route to the vault item list screen for the specified group.
    case group(_ group: VaultListGroup, filter: VaultFilterType)

    /// A route to the Credential Exchange import flow with the CXF specific route as a parameter.
    case importCXF(ImportCXFRoute)

    /// A route to the import logins screen.
    case importLogins

    /// A route to the vault list screen.
    case list

    /// A route to show a login request.
    ///
    /// - Parameter loginRequest: The login request to display.
    ///
    case loginRequest(_ loginRequest: LoginRequest)

    /// A route to switch accounts.
    ///
    /// - Parameter userId: The user id of the selected account.
    ///
    case switchAccount(userId: String)

    /// A route to the vault item selection screen.
    case vaultItemSelection(TOTPKeyModel)

    /// A route to the view item screen.
    ///
    /// - Parameters:
    ///   - id: The id of the item to display.
    ///   - masterPasswordRepromptCheckCompleted: Whether the master password reprompt check has
    ///     already been completed.
    ///
    case viewItem(id: String, masterPasswordRepromptCheckCompleted: Bool = false)

    /// A route to display the profile switcher.
    ///
    case viewProfileSwitcher
}
