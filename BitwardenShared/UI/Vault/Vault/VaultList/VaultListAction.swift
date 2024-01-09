import BitwardenSdk

// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// The add item button was pressed.
    case addItemPressed

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The copy TOTP Code button was pressed.
    ///
    case copyTOTPCode(_ code: String)

    /// An item in the vault was pressed.
    case itemPressed(item: VaultListItem)

    /// A forwarded profile switcher action
    case profileSwitcherAction(ProfileSwitcherAction)

    /// The text in the search bar was changed.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// A TOTP Code expired
    ///
    ///  - Parameter item: The VaultListItem with an expired code.
    ///
    case totpCodeExpired(_ item: VaultListItem)

    /// The selected vault filter changed.
    case vaultFilterChanged(VaultFilterType)

    /// The selected vault filter for search changed.
    case searchVaultFilterChanged(VaultFilterType)
}
