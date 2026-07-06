import BitwardenKit
import BitwardenResources

// MARK: - RegionType

/// A region that the user can select when creating or signing into their account.
extension RegionType {
    /// The regions the user can choose from in the region picker, in display order.
    static var userSelectableCases: [RegionType] {
        allCases.filter(\.isUserSelectable)
    }

    /// The region's apex domain, used as the host for the HTTPS auth-connector callback (Cloud
    /// regions only), or `nil` for self-hosted (which uses the `bitwarden://` custom scheme).
    var authCallbackHost: String? {
        switch self {
        case .europe: "bitwarden.eu"
        case .gov: "bitwarden-gov.com"
        case .internal: "bitwarden.pw"
        case .selfHosted: nil
        case .unitedStates: "bitwarden.com"
        }
    }

    /// The name for this region, localized.
    var localizedName: String {
        switch self {
        case .europe: Localizations.eu
        case .gov: Localizations.gov
        case .internal: "Internal" // Internal only, hidden from the region picker and not user facing.
        case .selfHosted: Localizations.selfHosted
        case .unitedStates: Localizations.us
        }
    }

    /// A description of the base url for this region.
    var baseURLDescription: String {
        switch self {
        case .europe: "bitwarden.eu"
        case .gov: "bitwarden-gov.com"
        // `.internal` is not user facing, so it mirrors self-hosted's description.
        case .internal, .selfHosted: Localizations.selfHosted
        case .unitedStates: "bitwarden.com"
        }
    }

    /// The default URLs for the region.
    var defaultURLs: EnvironmentURLData? {
        switch self {
        case .europe:
            .defaultEU
        case .gov:
            .defaultGov
        case .unitedStates:
            .defaultUS
        case .internal, .selfHosted:
            nil
        }
    }

    /// The name to be used by the error reporter.
    var errorReporterName: String {
        switch self {
        case .europe: "EU"
        case .gov: "Gov"
        case .internal: "Internal"
        case .selfHosted: "Self-Hosted"
        case .unitedStates: "US"
        }
    }

    /// Whether the user can choose this region in the region picker. Internal/QA regions (e.g.
    /// `.internal`) are excluded — they're detected automatically from the configured URL, never
    /// offered as a selectable option.
    var isUserSelectable: Bool {
        switch self {
        case .europe, .gov, .selfHosted, .unitedStates: true
        case .internal: false
        }
    }
}
