// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
public enum RegionType: CaseIterable {
    /// The United States region.
    case unitedStates

    /// The European region.
    case europe

    /// A self-hosted instance.
    case selfHosted

    /// The name for this region, localized.
    var localizedName: String {
        switch self {
        case .europe: return Localizations.eu
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return Localizations.us
        }
    }

    /// A description of the base url for this region.
    var baseUrlDescription: String {
        switch self {
        case .europe: return "bitwarden.eu"
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return "bitwarden.com"
        }
    }

    /// The default URLs for the region.
    var defaultURLs: EnvironmentUrlData? {
        switch self {
        case .europe:
            return .defaultEU
        case .unitedStates:
            return .defaultUS
        case .selfHosted:
            return nil
        }
    }
}
