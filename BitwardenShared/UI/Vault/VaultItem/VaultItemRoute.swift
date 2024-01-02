import BitwardenSdk
import SwiftUI

// MARK: VaultItemRoute

/// A route to a screen for a specific vault item.
enum VaultItemRoute: Equatable, Hashable {
    /// A route to the add item screen.
    ///
    /// - Parameter group: An optional `VaultListGroup` that the user wants to add an item for.
    ///
    case addItem(group: VaultListGroup? = nil)

    /// A route to display the specified alert.
    ///
    /// - Parameter alert: The alert to display.
    ///
    case alert(_ alert: Alert)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to edit an item
    ///
    case editItem(cipher: CipherView)

    /// A route to the username/password generator screen.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - emailWebsite: An optional website host used to generate usernames.
    ///
    case generator(_ type: GeneratorType, emailWebsite: String? = nil)

    /// A route to the manual totp screen for setting up TOTP.
    ///
    case setupTotpManual

    /// A route to the scan code screen. Deftaults to `.setupTotpManual` if camera is unavailable.
    ///
    case scanCode

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the item to display.
    ///
    case viewItem(id: String)
}

/// An action to perform on dismiss.
///
public struct DismissAction {
    /// A UUID for conformance to Equatable, Hashable.
    let id: UUID = .init()

    /// The action to perform on dismiss.
    var action: () -> Void
}

extension DismissAction: Equatable {
    public static func == (lhs: DismissAction, rhs: DismissAction) -> Bool {
        lhs.id == rhs.id
    }
}

extension DismissAction: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
