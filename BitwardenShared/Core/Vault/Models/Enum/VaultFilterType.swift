/// An enum that describes the options for filtering the user's vault.
///
enum VaultFilterType: Equatable {
    /// Show my and all organization vaults in the vault list.
    case allVaults

    /// Only show my vaults in the vault list.
    case myVault

    /// Only show the vault items for a specific organization.
    case organization(Organization)

    /// The title of the filter, as shown in the vault list.
    var filterTitle: String {
        switch self {
        case .allVaults:
            "\(Localizations.vaults): \(Localizations.all)"
        case .myVault:
            "\(Localizations.vault): \(Localizations.myVault)"
        case let .organization(organization):
            "\(Localizations.vault): \(organization.name)"
        }
    }

    /// The title of the filter, as shown in the menu to select a filter.
    var title: String {
        switch self {
        case .allVaults:
            Localizations.allVaults
        case .myVault:
            Localizations.myVault
        case let .organization(organization):
            organization.name
        }
    }
}
