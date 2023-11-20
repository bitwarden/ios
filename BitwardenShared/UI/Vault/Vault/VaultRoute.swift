import Foundation

// MARK: - VaultRoute

/// A route to a specific screen in the vault tab.
public enum VaultRoute: Equatable, Hashable {
    /// A route to the add account flow.
    case addAccount

    /// A route to the add item screen.
    ///
    /// - Parameter group: An optional `VaultListGroup` that the user wants to add an item for.
    case addItem(group: VaultListGroup? = nil)

    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    case alert(_ alert: Alert)

    /// A route to dismiss the screen currently presented modally.
    case dismiss

    /// A route to the vault item list screen for the specified group.
    case group(_ group: VaultListGroup)

    /// A route to the vault list screen.
    case list

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the item to display.
    case viewItem(id: String)
}
