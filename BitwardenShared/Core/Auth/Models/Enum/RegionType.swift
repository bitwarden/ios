// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
public enum RegionType {
    /// The European region.
    case europe

    /// A self-hosted instance.
    case selfHosted

    /// The United States region.
    case unitedStates

    /// The name for this region, localized.
    var localizedName: String {
        switch self {
        case .europe: return Localizations.eu
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return Localizations.us
        }
    }

    var baseUrlDescription: String {
        switch self {
        case .europe: return "bitwarden.eu"
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return "bitwarden.com"
        }
    }
}
