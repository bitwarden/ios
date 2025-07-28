import BitwardenKit
import BitwardenResources

// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
extension RegionType {
    /// The name for this region, localized.
    var localizedName: String {
        switch self {
        case .europe: return Localizations.eu
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return Localizations.us
        }
    }

    /// A description of the base url for this region.
    var baseURLDescription: String {
        switch self {
        case .europe: return "bitwarden.eu"
        case .selfHosted: return Localizations.selfHosted
        case .unitedStates: return "bitwarden.com"
        }
    }

    /// The default URLs for the region.
    var defaultURLs: EnvironmentURLData? {
        switch self {
        case .europe:
            return .defaultEU
        case .unitedStates:
            return .defaultUS
        case .selfHosted:
            return nil
        }
    }

    /// The name to be used by the error reporter.
    var errorReporterName: String {
        switch self {
        case .europe: return "EU"
        case .selfHosted: return "Self-Hosted"
        case .unitedStates: return "US"
        }
    }
}
