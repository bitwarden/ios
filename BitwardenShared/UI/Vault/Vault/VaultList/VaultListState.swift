import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    // MARK: Properties

    /// List of available item type for creation.
    var itemTypesUserCanCreate: [CipherType] = CipherType.canCreateCases

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// The state for the flight recorder toast banner displayed in the item list.
    var flightRecorderToastBanner = FlightRecorderToastBannerState()

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The user's import logins setup progress.
    var importLoginsSetupProgress: AccountSetupProgress?

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool = false

    /// Whether the user is eligible for an app review prompt.
    var isEligibleForAppReview: Bool = false

    /// The loading state of the My Vault screen.
    var loadingState: LoadingState<[VaultListSection]> = .loading(nil)

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text that the user is currently searching for.
    var searchText = ""

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType = .allVaults

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The vault filter used to display a single or all vaults for the user.
    var vaultFilterType: VaultFilterType = .allVaults

    // MARK: Computed Properties

    /// The navigation title for the view.
    var navigationTitle: String {
        if organizations.isEmpty || !canShowVaultFilter {
            Localizations.myVault
        } else {
            Localizations.vaults
        }
    }

    /// The state for showing the vault filter in search.
    var searchVaultFilterState: SearchVaultFilterRowState {
        SearchVaultFilterRowState(
            canShowVaultFilter: canShowVaultFilter,
            isPersonalOwnershipDisabled: isPersonalOwnershipDisabled,
            organizations: organizations,
            searchVaultFilterType: searchVaultFilterType,
        )
    }

    /// Whether the import logins action card should be shown.
    var shouldShowImportLoginsActionCard: Bool {
        importLoginsSetupProgress == .incomplete
    }

    /// The state for showing the vault filter.
    var vaultFilterState: SearchVaultFilterRowState {
        SearchVaultFilterRowState(
            canShowVaultFilter: canShowVaultFilter,
            isPersonalOwnershipDisabled: isPersonalOwnershipDisabled,
            organizations: organizations,
            searchVaultFilterType: vaultFilterType,
        )
    }

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.activeAccountInitials
    }
}
