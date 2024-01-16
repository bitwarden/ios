import BitwardenSdk
import Foundation

// MARK: - VaultRoute

/// A route to a specific screen in the vault tab.
public enum VaultRoute: Equatable, Hashable {
    /// A route to the add account flow.
    case addAccount

    /// A route to the add item screen.
    ///
    /// - Parameters
    ///   - allowTypeSelection: Whether the user should be able to select the type of item to add.
    ///   - group: An optional `VaultListGroup` that the user wants to add an item for.
    ///   - uri: A URI string used to populate the add item screen.
    ///
    case addItem(allowTypeSelection: Bool = true, group: VaultListGroup? = nil, uri: String? = nil)

    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    case alert(_ alert: Alert)

    /// A route to the autofill list screen.
    case autofillList

    /// A route to edit an item.
    ///
    /// - Parameter cipher: The `CipherView` to edit.
    ///
    case editItem(_ cipher: CipherView)

    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to the vault item list screen for the specified group.
    case group(_ group: VaultListGroup, filter: VaultFilterType)

    /// A route to the vault list screen.
    case list

    /// A route to switch accounts.
    ///
    /// - Parameter userId: The user id of the selected account.
    ///
    case switchAccount(userId: String)

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the item to display.
    case viewItem(id: String)
}
