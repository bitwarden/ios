// MARK: - VaultGroupEffect

/// Effects that can be handled by a `VaultGroupProcessor`.
enum VaultGroupEffect: Equatable {
    /// The vault group view appeared on screen.
    case appeared

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
