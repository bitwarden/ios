import BitwardenKit
import BitwardenSdk

// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// Navigate to add a new folder.
    case addFolder

    /// The app review prompt was attempted to be shown.
    case appReviewPromptShown

    /// The add item button was pressed.
    case addItemPressed(CipherType)

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The copy TOTP Code button was pressed.
    ///
    case copyTOTPCode(_ code: String)

    /// The vault list disappeared from the screen.
    case disappeared

    /// An item in the vault was pressed.
    case itemPressed(item: VaultListItem)

    /// The user tapped the go to settings button in the flight recorder banner.
    case navigateToFlightRecorderSettings

    /// A forwarded profile switcher action
    case profileSwitcher(ProfileSwitcherAction)

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The user tapped the get started button on the import logins action card.
    case showImportLogins

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
