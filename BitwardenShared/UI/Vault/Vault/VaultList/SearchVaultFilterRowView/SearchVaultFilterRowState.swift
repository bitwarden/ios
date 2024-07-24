// MARK: - SearchVaultFilterRowState

/// An object that defines the current state of a `SearchVaultFilterRowView`.
///
struct SearchVaultFilterRowState: Equatable {
    // MARK: Properties

    /// Whether the vault filter can be shown.
    var canShowVaultFilter = true

    /// Whether the policy is enforced to disable personal vault ownership.
    var isPersonalOwnershipDisabled: Bool = false

    /// The list of organizations the user is a member of.
    var organizations: [Organization] = []

    /// The search vault filter used to display a single or all vaults for the user.
    var searchVaultFilterType: VaultFilterType = .allVaults

    /// The list of vault filter options that can be used to filter the vault, if the user is a
    /// member of any organizations.
    var vaultFilterOptions: [VaultFilterType] {
        guard !organizations.isEmpty, canShowVaultFilter else { return [] }

        let sortedOrganizations = organizations
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map(VaultFilterType.organization)

        if isPersonalOwnershipDisabled {
            return [.allVaults] + sortedOrganizations
        } else {
            return [.allVaults, .myVault] + sortedOrganizations
        }
    }
}
