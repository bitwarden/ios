import BitwardenSdk
import SwiftUI

// MARK: VaultItemRoute

/// A route to a screen for a specific vault item.
enum VaultItemRoute: Equatable, Hashable {
    /// A route to the add folder screen.
    case addFolder

    /// A route to the add item screen.
    ///
    /// - Parameters:
    ///   - group: An optional `VaultListGroup` that the user wants to add an item for.
    ///   - hasPremium: Whether the user has premium.
    ///   - newCipherOptions: Optional options for creating a new cipher.
    ///   - organizationId: The organization id in case an organization was selected in the vault filter.
    ///   - type: The type of item to add.
    ///
    case addItem(
        group: VaultListGroup? = nil,
        hasPremium: Bool = false,
        newCipherOptions: NewCipherOptions? = nil,
        organizationId: String? = nil,
        type: CipherType,
    )

    /// A route to view the attachments.
    ///
    /// - Parameter cipher: The  `CipherView` to view/edit the attachments for.
    ///
    case attachments(_ cipher: CipherView)

    /// A route to the clone item screen.
    ///
    /// - Parameters:
    ///   - cipher: A `CipherView` to be cloned.
    ///   - hasPremium: Whether the user has premium.
    ///
    case cloneItem(cipher: CipherView, hasPremium: Bool)

    /// A route to dismiss the screen currently presented modally.
    ///
    /// - Parameter action: The action to perform on dismiss.
    ///
    case dismiss(_ action: DismissAction? = nil)

    /// A route to edit the collections of a cipher.
    case editCollections(CipherView)

    /// A route to edit an item.
    ///
    /// - Parameters:
    ///  - cipher: The `CipherView` to edit.
    ///  - hasPremium: Whether the user has premium.
    ///
    case editItem(_ cipher: CipherView, _ hasPremium: Bool)

    /// A route to a file selection route.
    ///
    /// - Parameter route: The file selection route to follow.
    ///
    case fileSelection(_ route: FileSelectionRoute)

    /// A route to the username/password generator screen.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - emailWebsite: An optional website host used to generate usernames.
    ///
    case generator(_ type: GeneratorType, emailWebsite: String? = nil)

    /// A route to the move to organization screen.
    case moveToOrganization(CipherView)

    /// A route to the password history view.
    ///
    /// - Parameter passwordHistory: The password history to display.
    ///
    case passwordHistory(_ passwordHistory: [PasswordHistoryView])

    /// A route to the file saving view.
    ///
    /// - Parameter temporaryUrl: The url where the file is currently stored.
    ///
    case saveFile(temporaryUrl: URL)

    /// A route to the manual totp screen for setting up TOTP.
    case setupTotpManual

    /// A route to the view item screen.
    ///
    /// - Parameter id: The id of the item to display.
    ///
    case viewItem(id: String)
}

enum VaultItemEvent {
    /// When the app should show the scan code screen.
    ///  Defaults to `.setupTotpManual` if camera is unavailable.
    case showScanCode
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
