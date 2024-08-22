// MARK: - VaultGroupAction

/// Actions that can be processed by a `VaultGroupProcessor`.
enum VaultGroupAction: Equatable, Sendable {
    /// The add item button was pressed.
    ///
    case addItemPressed

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The copy TOTP Code button was pressed.
    ///
    case copyTOTPCode(_ code: String)

    /// An item in the vault group was tapped.
    ///
    /// - Parameter item: The item that was tapped.
    ///
    case itemPressed(_ item: VaultListItem)

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The search bar's text was changed.
    ///
    case searchTextChanged(String)

    /// The selected vault filter for search changed.
    case searchVaultFilterChanged(VaultFilterType)

    /// The toast was shown or hidden.
    case toastShown(Toast?)
}
