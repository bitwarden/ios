import BitwardenKit
import BitwardenResources

// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
extension RegionType {
    /// The name for this region, localized.
    var localizedName: String {
        switch self {
        case .europe: Localizations.eu
        case .selfHosted: Localizations.selfHosted
        case .unitedStates: Localizations.us
        }
    }

    /// A description of the base url for this region.
    var baseURLDescription: String {
        switch self {
        case .europe: "bitwarden.eu"
        case .selfHosted: Localizations.selfHosted
        case .unitedStates: "bitwarden.com"
        }
    }

    /// The default URLs for the region.
    var defaultURLs: EnvironmentURLData? {
        switch self {
        case .europe:
            .defaultEU
        case .unitedStates:
            .defaultUS
        case .selfHosted:
            nil
        }
    }

    /// The name to be used by the error reporter.
    var errorReporterName: String {
        switch self {
        case .europe: "EU"
        case .selfHosted: "Self-Hosted"
        case .unitedStates: "US"
        }
    }
}
