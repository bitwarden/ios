import BitwardenSdk

// MARK: - VaultItemSelectionEffect

/// Actions that can be processed by a `VaultItemSelectionProcessor`.
///
enum VaultItemSelectionEffect: Equatable {
    /// A VoiceOver custom accessibility action for one of the more-options actions was activated.
    ///
    /// - Parameters:
    ///   - item: The item associated with the action.
    ///   - kind: The kind of more-options action that was activated.
    ///
    case accessibilityMoreOptionsActionPressed(_ item: VaultListItem, _ kind: MoreOptionsActionKind)

    /// Any initial data for the view should be loaded.
    case loadData

    /// The more button on an item in the vault group was tapped.
    case morePressed(VaultListItem)

    /// A forwarded profile switcher effect.
    case profileSwitcher(ProfileSwitcherEffect)

    /// Searches based on the keyword.
    case search(String)

    /// Stream the vault items for the user.
    case streamVaultItems

    /// Stream the show web icons setting.
    case streamShowWebIcons

    /// An item in the list was tapped.
    case vaultListItemTapped(VaultListItem)
}
