// MARK: - VaultGroupEffect

/// Effects that can be handled by a `VaultGroupProcessor`.
enum VaultGroupEffect: Equatable {
    /// A VoiceOver custom accessibility action for one of the more-options actions was activated.
    ///
    /// - Parameters:
    ///   - item: The item associated with the action.
    ///   - kind: The kind of more-options action that was activated.
    ///
    case accessibilityMoreOptionsActionPressed(_ item: VaultListItem, _ kind: MoreOptionsActionKind)

    /// The vault group view appeared on screen.
    case appeared

    /// An item in the vault group was tapped to be opened.
    ///
    /// - Parameter item: The item that was tapped.
    ///
    case itemPressed(_ item: VaultListItem)

    /// The more button on an item in the vault group was tapped.
    ///
    /// - Parameter item: The item associated with the more button that was tapped.
    ///
    case morePressed(_ item: VaultListItem)

    /// The refresh control was triggered.
    case refresh

    /// Searches based on the keyword.
    case search(String)

    /// Stream the list of organizations for the user.
    case streamOrganizations

    /// Stream the show web icons setting.
    case streamShowWebIcons
}
