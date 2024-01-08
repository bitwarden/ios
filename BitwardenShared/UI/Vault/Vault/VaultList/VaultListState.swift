// MARK: - VaultListState

/// An object that defines the current state of a `VaultListView`.
///
struct VaultListState: Equatable {
    // MARK: Properties

    /// The loading state of the My Vault screen.
    var loadingState: LoadingState<[VaultListSection]> = .loading

    /// The list of organizations the user is a member of.
    var organizations: [Organization] = []

    /// The user's current account profile state and alternative accounts.
    var profileSwitcherState: ProfileSwitcherState = .empty()

    /// An array of results matching the `searchText`.
    var searchResults: [VaultListItem] = []

    /// The text that the user is currently searching for.
    var searchText: String = ""

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType = .allVaults

    /// A toast message to show in the view.
    var toast: Toast?

    /// The vault filter used to display a single or all vaults for the user.
    var vaultFilterType: VaultFilterType = .allVaults

    // MARK: Computed Properties

    /// The navigation title for the view.
    var navigationTitle: String {
        if organizations.isEmpty {
            Localizations.myVault
        } else {
            Localizations.vaults
        }
    }

    /// The user's initials.
    var userInitials: String {
        profileSwitcherState.activeAccountInitials
    }

    /// The list of vault filter options that can be used to filter the vault, if the user is a
    /// member of any organizations.
    var vaultFilterOptions: [VaultFilterType] {
        guard !organizations.isEmpty else { return [] }
        return [.allVaults, .myVault] + organizations
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map(VaultFilterType.organization)
    }
}
