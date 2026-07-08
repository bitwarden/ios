import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    // MARK: Properties

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// The IDs of the vault list sections that are currently collapsed. Sections whose ID is not in
    /// this set are expanded.
    var collapsedSectionIds: Set<String> = []

    /// The state for the flight recorder toast banner displayed in the item list.
    var flightRecorderToastBanner = FlightRecorderToastBannerState()

    /// Whether the user has Premium subscription.
    var hasPremium: Bool = false

    /// The base url used to fetch icons.
    var iconBaseURL: URL?

    /// The user's import logins setup progress.
    var importLoginsSetupProgress: AccountSetupProgress?

    /// Whether the user is eligible for an app review prompt.
    var isEligibleForAppReview: Bool = false

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool = false

    /// List of available item type for creation.
    var itemTypesUserCanCreate: [CipherType] = CipherType.canCreateCases

    /// The loading state of the My Vault screen.
    var loadingState: LoadingState<[VaultListSection]> = .loading(nil)

    /// The list of organizations the user is a member of.
    var organizations = [Organization]()

    /// The data for the organization user notification banner, or `nil` if the banner should not be shown.
    var organizationUserNotificationBannerData: OrganizationUserNotificationBannerData?

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty()

    /// An array of results matching the `searchText`.
    var searchResults = [VaultListItem]()

    /// The text that the user is currently searching for.
    var searchText = ""

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType = .allVaults

    /// Whether the Archive Onboarding action card should be shown.
    var shouldShowArchiveOnboardingActionCard: Bool = false

    /// Whether the Premium Upgrade action card should be shown.
    var shouldShowPremiumUpgradeActionCard: Bool = false

    /// Whether the "subscription needs attention" action card should be shown.
    var shouldShowSubscriptionAttentionCard: Bool = false

    /// Whether the Upgraded to Premium action card should be shown.
    var shouldShowUpgradedToPremiumActionCard: Bool = false

    /// Whether to show the special web icons.
    var showWebIcons = true

    /// A toast message to show in the view.
    var toast: Toast?

    /// The url to open in the device's web browser.
    var url: URL?

    /// The vault filter used to display a single or all vaults for the user.
    var vaultFilterType: VaultFilterType = .allVaults

    // MARK: Computed Properties

    /// The active action card to show, determined by priority. Only one card is shown at a time.
    var activeActionCard: VaultListActionCard? {
        if shouldShowUpgradedToPremiumActionCard { return .upgradedToPremium }
        if shouldShowPremiumUpgradeActionCard { return .upgradeNeeded }
        if shouldShowSubscriptionAttentionCard { return .subscriptionNeedsAttention }
        if shouldShowArchiveOnboardingActionCard { return .introducingArchive }
        if shouldShowImportLoginsActionCard { return .importItems }
        return nil
    }

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

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.activeAccountInitials
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
}

// MARK: - VaultListActionCard

/// The action card to show on the vault list, determined by priority. Only one is shown at a time.
enum VaultListActionCard {
    /// The import saved logins card.
    case importItems

    /// The archive onboarding card.
    case introducingArchive

    /// The subscription needs attention card for past-due or update-payment users.
    case subscriptionNeedsAttention

    /// The post-upgrade confirmation card (highest priority).
    case upgradedToPremium

    /// The upgrade-to-premium banner for free users.
    case upgradeNeeded
}
