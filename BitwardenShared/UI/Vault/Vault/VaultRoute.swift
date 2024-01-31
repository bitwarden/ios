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
    ///   - newCipherOptions: Options that can be used to pre-populate the add item screen.
    ///
    case addItem(
        allowTypeSelection: Bool = true,
        group: VaultListGroup? = nil,
        newCipherOptions: NewCipherOptions? = nil
    )

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
    case group(VaultGroupContent)

    /// A route to the vault list screen.
    case list

    /// A route to the login screen after the vault has been locked.
    ///
    /// - Parameter account: The user's account.
    ///
    case lockVault(account: Account)

    /// A route to show a login request.
    ///
    /// - Parameter loginRequest: The login request to display.
    ///
    case loginRequest(_ loginRequest: LoginRequest)

    /// A route to log the user out.
    ///
    /// - Parameter userInitiated: Did a user action trigger the logout.
    ///
    case logout(userInitiated: Bool)

    /// A route to switch accounts.
    ///
    /// - Parameter userId: The user id of the selected account.
    ///
    case switchAccount(userId: String)

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the item to display.
    ///
    case viewItem(id: String)
}

public struct VaultGroupContent: Equatable, Hashable {
    var group: VaultListGroup

    var filter: VaultFilterType

    @AlwaysEqual var filterDelegate: VaultFilterDelegate?

    public func hash(into hasher: inout Hasher) {
        hasher.combine(group)
        hasher.combine(filter)
    }
}

@propertyWrapper
struct AlwaysEqual<Value>: Equatable {
    var wrappedValue: Value
    static func == (lhs: AlwaysEqual<Value>, rhs: AlwaysEqual<Value>) -> Bool {
        true
    }
}
