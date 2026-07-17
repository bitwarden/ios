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
    /// The import logins card is additionally gated on the vault being empty, since it is only
    /// relevant to users who have not yet added any items.
    var activeActionCard: VaultListActionCard? {
        VaultListActionCard.allCases.first { shouldShow($0) }
    }

    /// Whether the vault is in an empty data state (loaded successfully with no sections).
    var isVaultEmpty: Bool {
        guard case let .data(sections) = loadingState else { return false }
        return sections.isEmpty
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

    // MARK: Private

    /// Whether a given action card's eligibility conditions are met.
    ///
    /// - Parameters:
    ///   - card: The action card to evaluate.
    ///
    /// - Returns: `true` if the card should be displayed; `false` otherwise.
    private func shouldShow(_ card: VaultListActionCard) -> Bool {
        switch card {
        case .upgradedToPremium: shouldShowUpgradedToPremiumActionCard
        case .upgradeNeeded: shouldShowPremiumUpgradeActionCard
        case .subscriptionNeedsAttention: shouldShowSubscriptionAttentionCard
        case .introducingArchive: shouldShowArchiveOnboardingActionCard
        case .importItems: shouldShowImportLoginsActionCard && isVaultEmpty
        }
    }
}

// MARK: - VaultListActionCard

/// The action card to show on the vault list. Only one is shown at a time.
/// Cases are declared in priority order from highest to lowest.
enum VaultListActionCard: CaseIterable, Equatable {
    /// The post-upgrade confirmation card.
    case upgradedToPremium

    /// The upgrade-to-premium banner for free users.
    case upgradeNeeded

    /// The subscription needs attention card for past-due or update-payment users.
    case subscriptionNeedsAttention

    /// The archive onboarding card.
    case introducingArchive

    /// The import saved logins card.
    case importItems
}
