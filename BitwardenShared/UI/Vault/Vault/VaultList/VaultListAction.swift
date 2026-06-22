import BitwardenKit
import BitwardenSdk

// MARK: - VaultListAction

/// Actions that can be processed by a `VaultListProcessor`.
enum VaultListAction: Equatable {
    /// Navigate to add a new folder.
    case addFolder

    /// The add item button was pressed.
    case addItemPressed(CipherType)

    /// The app review prompt was attempted to be shown.
    case appReviewPromptShown

    /// The url has been opened so clear the value in the state.
    case clearURL

    /// The copy TOTP Code button was pressed.
    ///
    case copyTOTPCode(_ code: String)

    /// The vault list disappeared from the screen.
    case disappeared

    /// The user tapped the button to go to archive.
    case goToArchive

    /// An item in the vault was pressed.
    case itemPressed(item: VaultListItem)

    /// The "Learn more" button on the upgraded to Premium action card was tapped.
    case learnMoreAboutPremium

    /// The user tapped the go to settings button in the flight recorder banner.
    case navigateToFlightRecorderSettings

    /// A forwarded profile switcher action
    case profileSwitcher(ProfileSwitcherAction)

    /// The user has started or stopped searching.
    case searchStateChanged(isSearching: Bool)

    /// The text in the search bar was changed.
    case searchTextChanged(String)

    /// The selected vault filter for search changed.
    case searchVaultFilterChanged(VaultFilterType)

    /// A vault list section header was tapped to expand or collapse the section.
    ///
    /// - Parameters:
    ///   - sectionId: The ID of the section that was expanded or collapsed.
    ///   - isExpanded: Whether the section is now expanded.
    ///
    case sectionExpandToggled(sectionId: String, isExpanded: Bool)

    /// The user tapped the get started button on the import logins action card.
    case showImportLogins

    /// The toast was shown or hidden.
    case toastShown(Toast?)

    /// A TOTP Code expired
    ///
    ///  - Parameter item: The VaultListItem with an expired code.
    ///
    case totpCodeExpired(_ item: VaultListItem)

    /// The upgrade to Premium button was tapped.
    case upgradeToPremium

    /// The "View plan" button on the subscription needs attention action card was tapped.
    case viewPlan

    /// The selected vault filter changed.
    case vaultFilterChanged(VaultFilterType)
}
